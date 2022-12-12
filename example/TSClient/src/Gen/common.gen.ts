export interface IStubClient {
    send(request: unknown, servicePath: string): Promise<unknown>;
}
