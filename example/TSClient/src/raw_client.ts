import { IStubClient } from "./Gen/common.gen";

export class RawAPIClient implements IStubClient {
  baseURL: string

  constructor(baseURL: string) {
    this.baseURL = baseURL;
  }

  async send(request: unknown, servicePath: string): Promise<unknown> {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    headers["Authorization"] = `Bearer xxxxxxxx`;
  
    const res = await fetch(new URL(servicePath, this.baseURL).toString(), {
      method: "POST",
      headers: headers,
      body: JSON.stringify(request),
    });
  
    const json = await res.json();
  
    if (!res.ok) {
      const errorFrame = json as { errorMessage: string };
      if ("errorMessage" in errorFrame) { 
        throw new Error(errorFrame.errorMessage);
      } else {
        throw new Error("unexpected error");
      }
    }
  
    return json;
  }
}

export type StubClientOptions = {
  headers?: () => Record<string, string>;
}

export class FetchHTTPStubResponseError extends Error {
  readonly path: string;
  readonly response: Response;
  constructor(
    path: string,
    response: Response
  ) {
    super(`ResponseError. path=${path}, status=${response.status}`);
    this.path = path;
    this.response = response;
  }
}

export const createStubClient = (baseURL: string, options?: StubClientOptions): IStubClient => {
  return {
    async send(request, servicePath) {
      const headers: Record<string, string> = {
        "Content-Type": "application/json",
      };
      if (options?.headers) {
        Object.assign(headers, options.headers());
      }
    
      const res = await fetch(new URL(servicePath, baseURL).toString(), {
        method: "POST",
        headers: headers,
        body: JSON.stringify(request),
      });
    
      if (!res.ok) {
        throw new FetchHTTPStubResponseError(servicePath, res);
      }
      return await res.json();
    },
  }
}
