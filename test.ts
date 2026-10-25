class Person {
	name: string;
	constructor(name: string) {
		this.name = name;
	}
}

type yusluv =  {
	name: string;
}

type suit = "west" | 'north';
const man: suit
const yusu: yusluv = {
	name: "bimpe",
};

console.log(yusu.name);

const yu = new Person("gany");
console.log(yu.name);

const yusuf: string[] = ["kay", "kayode", "ganiyu"];

for (const yus of yusuf) {
	console.log(yus);
}
