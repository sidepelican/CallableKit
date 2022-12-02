import { buildAccountClient } from "./Gen/Account.gen.js";
import { buildEchoClient } from "./Gen/Echo.gen.js";
import { User_ID } from "./Gen/User.gen.js";
import { RawAPIClient } from "./raw_client.js";

async function main() {
  const rawClient = new RawAPIClient("http://127.0.0.1:8080");
  const echoClient = buildEchoClient(rawClient);
  const accountClient = buildAccountClient(rawClient);

  {
    const res = await echoClient.hello({ name: "TypeScript" });
    console.log(res.message);
  }

  {
    const res = await echoClient.testTypicalEntity({ id: "id" as User_ID, name: "name" });
    console.log(JSON.stringify(res));
  }
  
  {
    const res = await echoClient.testComplexType({
      a: {
        x: [
          { k: { _0: { x: { x: "hello" } } } },
          { i: { _0: 100 } },
          { n: {} },
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
    let res = await accountClient.signin({
        email: "example@example.com",
        password: "password",
    });
    console.log(JSON.stringify(res));
  }
}

main();
