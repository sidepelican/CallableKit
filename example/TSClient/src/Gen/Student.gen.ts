import { GenericIDz, GenericIDz_JSON, GenericIDz_decode } from "./GenericID.gen.js";

export type Student = {
    id: Student_IDz;
    name: string;
};

export type Student_JSON = {
    id: Student_IDz_JSON;
    name: string;
};

export function Student_decode(json: Student_JSON): Student {
    return {
        id: Student_IDz_decode(json.id),
        name: json.name
    };
}

export type Student_IDz = GenericIDz<Student>;

export type Student_IDz_JSON = GenericIDz_JSON<Student_JSON>;

export function Student_IDz_decode(json: Student_IDz_JSON): Student_IDz {
    return GenericIDz_decode(json, Student_decode);
}
