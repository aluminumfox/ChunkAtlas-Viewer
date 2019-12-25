/**
 * @file db-writer.js
 *
 * Handles privileged database access that may create or update database
 * values.
 */

const { Pool } = require("pg");
const { isDefined } = require("../../validate.js");
const pool = new Pool({
    user: process.env.PGWRITER,
    password: process.env.PGWRITER_PASSWORD
});

pool.on("error", (err, client) => {
    logger.error("Postgres error: " + err);    
});

const DBUser = require("../db-user.js");
const QueryBuilder = require("../query-builder.js");
const resultHandler = require("../result-handler.js");
const writer = new DBUser(pool);

/**
 * Sets one or more cell values within a specific table.
 *
 * @param tableEnum     An Enum type representing the database table to update.
 *
 * @param columnValues  An object holding a set of key:value pairs,
 *                      where each key is a column enum value, and each
 *                      value is the parameter that should be assigned to
 *                      that column.
 *
 * @param condition     An SQL condition string used to determine which rows
 *                      should be updated.
 *
 * @param params        An optional parameter or array of parameters that will
 *                      be inserted into the query.
 *
 * @return              A Promise that may be used to find if and when the new
 *                      value is successfully applied. If no rows are changed
 *                      or a database error occurs, the promise will reject.
 */
writer.setColumnValues
        = function(tableEnum, columnValues, condition, params) {
    if (isDefined(params) && ! Array.isArray(params)) {
        params = [ params ];
    }
    const builder = new QueryBuilder(tableEnum);
    builder.setConditions(condition, params);
    return resultHandler.handleErrors(builder.update(this._pool, columnValues))
    .then((result) => {
        if (result.rowCount === 0) {
            throw new Error("Found no rows in '" + tableEnum.name
                    + "' where '" + condition + "' (params = '" + params
                    + ")'");
        }
    });
};

/**
 * Attempts to insert a set of values into a database table.
 *
 * @param tableEnum     An Enum type representing the database table to
 *                      update.
 *
 * @param columns       The columns to set in the inserted row or rows.
 *
 * @param values        An array of row values to insert. Each row value
 *                      is an array of column values, listed in the same
 *                      order as in the columns parameter.
 *
 * @return              A Promise that will resolve with the number of added
 *                      columns within the table, or reject if errors occurred
 *                      or no columns were added.
 *
 */
writer.insertRows = function(tableEnum, columns, values) {
    const builder = new QueryBuilder(tableEnum);
    return resultHandler.handleErrors(
            builder.insert(this._pool, columns, values))
    .then((result) => {
        if (result === 0) {
            throw new Error("Inserted no rows into table '" + tableEnum.name
                    + "'.");
        }
        return result.rowCount;
    });
};

/**
 * Attempts to delete a set of rows from a database table.
 *
 * @param condition     An SQL condition string used to determine which rows
 *                      should be updated.
 *
 * @param params        An optional parameter or array of parameters that will
 *                      be inserted into the query.
 *
 * @return              A Promise that will resolve with the number of deleted
 *                      columns within the table, or reject if errors
 *                      occurred.
 */
writer.deleteRows = function(tableEnum, conditions, params) {
    const builder = new QueryBuilder(tableEnum);
    if (isDefined(conditions)) {
        if (isDefined(params) && ! Array.isArray(params)) {
            params = [ params ];
        }
        builder.setConditions(conditions, params);
    }
    return resultHandler.handleErrors(builder.deleteQuery(this._pool))
    .then((result) => {
        return result.rowCount;
    });

};

module.exports = writer;
