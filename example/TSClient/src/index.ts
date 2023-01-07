import { bindAccount } from "./Gen/APIDefinition/Account.js";
import { bindEcho } from "./Gen/APIDefinition/Echo.js";
import { Student, Student_IDz } from "./Gen/APIDefinition/Entity/Student.js";
import { User_ID } from "./Gen/APIDefinition/Entity/User.js";
import { createStubClient } from "./Gen/CallableKit.js";

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
    const id = { rawValue: "id" } as User_ID;
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
      id: { rawValue: "0001" } as Student_IDz,
      name: "taro"
    }
    const res = await echoClient.testTypeAliasToRawRepr(student);
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
