import * as express from "express";
import { User as AppUser } from "../app/user/user.repository";

declare global {
  namespace Express {
    interface Request {
      user: AppUser;
    }
  }
}
