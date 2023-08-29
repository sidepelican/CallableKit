import { TagRecord } from "../../common.gen.js";

export type User = {
    id: User_ID;
    name: string;
} & TagRecord<"User">;

export type User_ID = string & TagRecord<"User_ID">;
