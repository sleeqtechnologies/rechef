import { AnyPgTable } from "drizzle-orm/pg-core";
import type { PostgresJsDatabase } from "drizzle-orm/postgres-js";
import { AsyncLocalStorage } from "node:async_hooks";

type AfterCommitCallback = () => Promise<unknown>;

export default function database<TSchema extends Record<string, unknown>>(
  db: PostgresJsDatabase<TSchema>
) {
  const asyncLocalStorage = new AsyncLocalStorage<TransactionState>();

  type DatabaseType = PostgresJsDatabase<TSchema>;
  type Transaction = Parameters<Parameters<DatabaseType["transaction"]>[0]>[0];

  type TransactionState = {
    transaction: Transaction;
    committed: boolean;
    afterCommit: AfterCommitCallback[];
  };

  type TransactionResponse = {
    transaction: Transaction;
    afterCommit: (callback: AfterCommitCallback) => void;
  };

  type TransactionCallback<Type> = (trx: TransactionResponse) => Promise<Type>;

  function getExecutor() {
    const transactionState = asyncLocalStorage.getStore();
    if (transactionState && !transactionState.committed) {
      return transactionState.transaction;
    }
    return db;
  }

  function selectAll() {
    return getExecutor().select();
  }

  function select<SelectedFields extends Parameters<DatabaseType["select"]>[0]>(
    selectedFields: SelectedFields
  ) {
    return getExecutor().select(selectedFields);
  }

  function dbSelect(): ReturnType<typeof selectAll>;
  function dbSelect<SelectedFields extends Parameters<DatabaseType["select"]>[0]>(
    selectedFields: SelectedFields
  ): ReturnType<typeof select>;
  function dbSelect<SelectedFields extends Parameters<DatabaseType["select"]>[0]>(
    selectedFields?: SelectedFields
  ) {
    return selectedFields ? select(selectedFields) : selectAll();
  }

  return {
    delete: <Table extends AnyPgTable>(table: Table) => getExecutor().delete(table),
    insert: <Table extends AnyPgTable>(table: Table) => getExecutor().insert(table),
    update: <Table extends AnyPgTable>(table: Table) => getExecutor().update(table),
    query: getExecutor().query,
    select: dbSelect,
    transaction: async <Type>(callback: TransactionCallback<Type>) => {
      const transactionState = asyncLocalStorage.getStore();
      if (transactionState && !transactionState.committed) {
        console.log("you are already in transaction. using current transaction instance");
        return callback({
          transaction: transactionState.transaction,
          afterCommit(callback: AfterCommitCallback) {
            transactionState.afterCommit.push(callback);
          },
        });
      }

      const afterCommit: AfterCommitCallback[] = [];

      const result = await db.transaction((transaction) => {
        const newTransactionState: TransactionState = {
          transaction,
          committed: false,
          afterCommit,
        };

        return new Promise<Type>((resolve, reject) => {
          asyncLocalStorage.run(newTransactionState, async () => {
            try {
              const result = await callback({
                transaction,
                afterCommit(callback: AfterCommitCallback) {
                  newTransactionState.afterCommit.push(callback);
                },
              });
              resolve(result);
            } catch (error) {
              reject(error);
            } finally {
              newTransactionState.committed = true;
            }
          });
        });
      });

      for (const afterCommitCallback of afterCommit) {
        await afterCommitCallback();
      }

      return result;
    },
  };
}
