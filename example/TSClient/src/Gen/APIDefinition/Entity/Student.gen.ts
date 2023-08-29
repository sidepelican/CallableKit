import { TagRecord } from "../../common.gen.js";
import { GenericID } from "./GenericID.gen.js";

export type Student = {
    id: Student_ID;
    name: string;
} & TagRecord<"Student">;

export type Student_ID = GenericID<Student>;
