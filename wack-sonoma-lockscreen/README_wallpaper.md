## Making wallpaper change consistently
1. Create the autostart file:

   ```bash
   mkdir -p ~/.local/bin ~/.local/share/wack-sync
  ```

cat > ~/.local/bin/wack-gdm-sync <<'EOF'
#!/usr/bin/env python3
"""Keeps the WACK GDM wallpaper in sync without locking the screen."""
import getpass, glob, json, os, shutil, time
from urllib.parse import unquote, urlparse

import gi
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import Gio, GLib, GdkPixbuf

USER = getpass.getuser()
SHARED = '/var/tmp/wack/shared'
META = f'{SHARED}/wack-shared-wallpaper-{USER}.json'
BACKUP_DIR = os.path.expanduser('~/.local/share/wack-sync')
MAX_DIM = 2560
POLL_SECONDS = 2


def log(msg):
    print(f'[wack-gdm-sync] {msg}', flush=True)


bg = Gio.Settings.new('org.gnome.desktop.background')
iface = Gio.Settings.new('org.gnome.desktop.interface')
ext = None
_src = Gio.SettingsSchemaSource.get_default()
if _src and _src.lookup('org.gnome.shell.extensions.wack-lockscreen-clock', True):
    ext = Gio.Settings.new('org.gnome.shell.extensions.wack-lockscreen-clock')


def uri_to_path(uri):
    if uri.startswith('file://'):
        return unquote(urlparse(uri).path)
    if uri.startswith('/'):
        return uri
    return None


def desired():
    light = bg.get_string('picture-uri')
    dark = bg.get_string('picture-uri-dark')
    if ext and ext.get_boolean('lockscreen-wallpaper-enable'):
        custom = ext.get_string('lockscreen-wallpaper-path')
        if custom and os.path.exists(custom.replace('file://', '', 1)):
            light = dark = custom if custom.startswith('file://') else 'file://' + custom
    dark = dark or light
    light = light or dark
    return {'light': light, 'dark': dark,
            'scheme': iface.get_enum('color-scheme'),
            'style': bg.get_enum('picture-options')}


def stat_of(uri):
    p = uri_to_path(uri) if uri else None
    if not p:
        return None
    try:
        st = os.stat(p)
        return p, int(st.st_mtime), st.st_size
    except OSError:
        return None


def load_meta():
    try:
        with open(META) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def supported(d):
    # Solid colours and XML slideshows are left to the extension.
    if d['style'] == 0:
        return False
    for u in (d['light'], d['dark']):
        if not u or u.lower().endswith('.xml') or stat_of(u) is None:
            return False
    return True


def up_to_date(meta, d):
    if meta.get('color_scheme') != d['scheme'] or meta.get('style') != d['style']:
        return False
    for tag in ('light', 'dark'):
        v = (meta.get('variants') or {}).get(tag)
        s = stat_of(d[tag])
        if not v or not s:
            return False
        if (v.get('source_uri') != d[tag] or v.get('source_mtime') != s[1]
                or v.get('source_size') != s[2]):
            return False
        t = v.get('target_path')
        if not t or not os.path.exists(t):
            return False
    return True


def make_jpg(src, dest):
    try:
        pb = GdkPixbuf.Pixbuf.new_from_file(src)
        w, h = pb.get_width(), pb.get_height()
        if w > MAX_DIM or h > MAX_DIM:
            if w > h:
                nw, nh = MAX_DIM, round(h * MAX_DIM / w)
            else:
                nw, nh = round(w * MAX_DIM / h), MAX_DIM
            pb = pb.scale_simple(nw, nh, GdkPixbuf.InterpType.BILINEAR)
        tmp = f'{dest}.tmp.{os.getpid()}'
        pb.savev(tmp, 'jpeg', ['quality'], ['80'])
        os.chmod(tmp, 0o644)
        os.replace(tmp, dest)
        return dest
    except Exception as e:
        log(f'pixbuf failed ({e}), copying original instead')
        dest2 = os.path.splitext(dest)[0] + (os.path.splitext(src)[1] or '.jpg')
        shutil.copyfile(src, dest2)
        os.chmod(dest2, 0o644)
        return dest2


def sync(meta, d):
    ts = int(time.time() * 1000)

    def process(tag):
        path, mtime, size = stat_of(d[tag])
        dest = f'{SHARED}/wack-shared-wallpaper-{USER}-{tag}-{ts}.jpg'
        return make_jpg(path, dest), mtime, size

    results = {}
    if d['light'] == d['dark']:
        target, mt, sz = process('light')
        results['light'] = results['dark'] = (target, mt, sz)
    else:
        for tag in ('light', 'dark'):
            results[tag] = process(tag)

    variants = meta.setdefault('variants', {})
    for tag, (target, mt, sz) in results.items():
        v = variants.setdefault(tag, {})
        v.update({
            'source_uri': d[tag], 'source_mtime': mt, 'source_size': sz,
            'uri': 'file://' + target, 'target_path': target,
            'slideshow_xml_text': None, 'resolved_slide_path': None,
            'resolved_slide_progress': 0, 'is_color': False,
            'metadataMatches': True,
        })

    av = variants['dark' if d['scheme'] == 1 else 'light']
    meta.update({
        'color_scheme': d['scheme'], 'style': d['style'], 'is_color': False,
        'source_uri': av['source_uri'], 'source_mtime': av['source_mtime'],
        'source_size': av['source_size'], 'uri': av['uri'],
        'slideshow_xml_text': None, 'resolved_slide_path': None,
        'resolved_slide_progress': 0,
    })

    # Image first, manifest second, so GDM never sees a dangling reference.
    tmp = f'{META}.tmp.{os.getpid()}'
    with open(tmp, 'w') as f:
        json.dump(meta, f, separators=(',', ':'))
    os.chmod(tmp, 0o644)
    os.replace(tmp, META)

    keep = {v['target_path'] for v in variants.values() if v.get('target_path')}
    for pattern in ('jpg', 'jpeg', 'png'):
        for old in glob.glob(f'{SHARED}/wack-shared-wallpaper-{USER}-*.{pattern}'):
            if old not in keep:
                try:
                    os.remove(old)
                except OSError:
                    pass


state = {'seen': None, 'handled': None}


def tick():
    meta = load_meta()
    if meta is None:
        return True          # no manifest yet: lock the screen once first
    d = desired()
    if not supported(d) or up_to_date(meta, d):
        state['seen'] = None
        return True
    key = (d['light'], d['dark'], d['scheme'], d['style'],
           stat_of(d['light']), stat_of(d['dark']))
    if key != state['seen']:
        state['seen'] = key  # wait one more poll so a half-written file settles
        return True
    if key == state['handled']:
        return True
    state['handled'] = key
    try:
        sync(meta, d)
        log('GDM wallpaper updated')
    except Exception as e:
        log(f'sync failed: {e}')
    return True


os.makedirs(BACKUP_DIR, exist_ok=True)
backup = os.path.join(BACKUP_DIR, 'manifest.original.json')
if os.path.exists(META) and not os.path.exists(backup):
    shutil.copyfile(META, backup)
    log(f'backed up manifest to {backup}')

GLib.timeout_add_seconds(POLL_SECONDS, tick)
GLib.MainLoop().run()
EOF
chmod +x ~/.local/bin/wack-gdm-sync

   ```
---

 2. Run it automatically at every login
   ```
   mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/wack-gdm-sync.service <<'EOF'
[Unit]
Description=Sync wallpaper to WACK GDM without locking
After=graphical-session.target
PartOf=graphical-session.target

[Service]
ExecStart=/usr/bin/python3 %h/.local/bin/wack-gdm-sync
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now wack-gdm-sync.service
journalctl --user -u wack-gdm-sync -f
   ```
---
