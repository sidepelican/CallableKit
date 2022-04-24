
import fetch from "node-fetch";
import { IRawClient } from "./Gen/common.gen";

export class RawAPIClient implements IRawClient {
  baseURL: string

  constructor(baseURL: string) {
    this.baseURL = baseURL;
  }

  async fetch(request: unknown, servicePath: string): Promise<unknown> {
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

