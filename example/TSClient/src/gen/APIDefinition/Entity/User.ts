import { TagRecord } from "../../common.js";

export type User = {
    id: User_ID;
    name: string;
} & TagRecord<"User">;

export type User_JSON = {
    id: User_ID_JSON;
    name: string;
};

export function User_decode(json: User_JSON): User {
    const id = User_ID_decode(json.id);
    const name = json.name;
    return {
        id: id,
        name: name
    };
}

export function User_encode(entity: User): User_JSON {
    const id = User_ID_encode(entity.id);
    const name = entity.name;
    return {
        id: id,
        name: name
    };
}

export type User_ID = {
    rawValue: string;
} & TagRecord<"User_ID">;

export type User_ID_JSON = string;

export function User_ID_decode(json: User_ID_JSON): User_ID {
    return {
        rawValue: json
    };
}

export function User_ID_encode(entity: User_ID): User_ID_JSON {
    return entity.rawValue;
}
