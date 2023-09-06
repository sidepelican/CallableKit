import { bindAccount } from "./Gen/APIDefinition/Account.gen.js";
import { bindEcho } from "./Gen/APIDefinition/Echo.gen.js";
import { Student, Student2, Student3, Student4 } from "./Gen/APIDefinition/Entity/Student.gen.js";
import { User_ID } from "./Gen/APIDefinition/Entity/User.gen.js";
import { createStubClient } from "./Gen/CallableKit.gen.js";

async function main() {
  const stub = createStubClient("http://127.0.0.1:8080");
  const echoClient = bindEcho(stub);
  const accountClient = bindAccount(stub);

  {
    const res = await echoClient.hello({ name: "TypeScript" });
    console.log(res.message);
  }

  {
    const res = await echoClient.tommorow(new Date());
    console.log(res);
  }

  {
    const id = "id" as User_ID;
    const res = await echoClient.testTypicalEntity({ id, name: "name" });
    console.log(JSON.stringify(res));
  }

  {
    const res = await echoClient.testComplexType({
      a: {
        x: [
          { kind: "k", k: { _0: { x: { x: "hello" } } } },
          { kind: "i", i: { _0: 100 } },
          { kind: "n", n: {} },
          null
        ]
      }
    })
    console.log(JSON.stringify(res));
  }

  {
    await echoClient.emptyRequestAndResponse();
  }

  {
    const student: Student = {
      id: "0001",
      name: "taro"
    }
    const res = await echoClient.testTypeAliasToRawRepr(student);
    console.log(JSON.stringify(res));
  }

  {
    const student: Student2 = {
      id: "0002",
      name: "taro"
    }
    const res = await echoClient.testRawRepr(student);
    console.log(JSON.stringify(res));
  }

  {
    const student: Student3 = {
      id: { kind: "id", id: { _0: "0003" }},
      name: "taro"
    }
    const res = await echoClient.testRawRepr2(student);
    console.log(JSON.stringify(res));
  }

  {
    const student: Student4 = {
      id: { kind: "id", id: { _0: "0004" }},
      name: "taro"
    }
    const res = await echoClient.testRawRepr3(student);
    console.log(JSON.stringify(res));
  }

  {
    let res = await accountClient.signin({
        email: "example@example.com",
        password: "password",
    });
    console.log(JSON.stringify(res));
  }
}

main();
