export interface IStubClient {
    send(request: unknown, servicePath: string): Promise<unknown>;
}

export type Headers = Record<string, string>;

export type StubClientOptions = {
    headers?: () => Headers | Promise<Headers>;
    mapResponseError?: (e: FetchHTTPStubResponseError) => Error;
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
            let optionHeaders: Headers = {};
            if (options?.headers) {
                optionHeaders = await options.headers();
            }
            const res = await fetch(new URL(servicePath, baseURL).toString(), {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    ...optionHeaders
                },
                body: JSON.stringify(request)
            });
            if (! res.ok) {
                const e = new FetchHTTPStubResponseError(servicePath, res);
                if (options?.mapResponseError) {
                    throw options.mapResponseError(e);
                } else {
                    throw e;
                }
            }
            return await res.json();
        }
    };
};

export function Date_encode(d: Date) {
    return d.getTime();
}

export function Date_decode(unixMilli: number) {
    return new Date(unixMilli);
}
