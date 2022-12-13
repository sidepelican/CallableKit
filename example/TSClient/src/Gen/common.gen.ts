export interface IStubClient {
    send(request: unknown, servicePath: string): Promise<unknown>;
}

export type StubClientOptions = {
    headers?: () => Record<string, string>;
};

export class FetchHTTPStubResponseError extends Error {
    readonly path: string;
    readonly response: Response;

    constructor(path: string, response: Response) {
        super(`ResponseError. path=${path}, status=${response.status}`);
        this.path = path;
        this.response = response;
    }
}

export const createStubClient = (baseURL: string, options?: StubClientOptions): IStubClient => {
    return {
        async send(request, servicePath) {
            const headers: Record<string, string> = {
                "Content-Type": "application/json"
            };
            if (options?.headers) {
                Object.assign(headers, options.headers());
            }
            const res = await fetch(new URL(servicePath, baseURL), {
                method: "POST",
                headers,
                body: JSON.stringify(request)
            });
            if (! res.ok) {
                throw new FetchHTTPStubResponseError(servicePath, res);
            }
            return await res.json();
        }
    };
};
