export interface IRawClient {
  fetch(request: unknown, servicePath: string): Promise<unknown>
}