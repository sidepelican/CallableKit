import { buildEchoClient } from "./Gen/Echo.gen.js";
import { RawAPIClient } from "./raw_client.js";

async function main() {
  const rawClient = new RawAPIClient("http://127.0.0.1:8080");
  const echoClient = buildEchoClient(rawClient);

  const res = await echoClient.hello({ name: "TypeScript" });
  console.log(res.message);
}

main();
