import { IRawClient } from "./common.gen";

export interface IEchoClient {
  hello(request: EchoHelloRequest): Promise<EchoHelloResponse>
}

class EchoClient implements IEchoClient {
  rawClient: IRawClient;

  constructor(rawClient: IRawClient) {
    this.rawClient = rawClient;
  }

  async hello(request: EchoHelloRequest): Promise<EchoHelloResponse> {
    return await this.rawClient.fetch(request, "Echo/hello") as EchoHelloResponse
  }
}

export const buildEchoClient = (raw: IRawClient): IEchoClient => new EchoClient(raw);

export type EchoHelloRequest = {
    name: string;
};

export type EchoHelloResponse = {
    message: string;
};
