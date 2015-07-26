/*
 * Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package ftldb.ext.sql;


import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


/**
 * This class contains the static result of fetching from a {@link ResultSet} and its metadata. This is needed because
 * the original result set can be fetched only once, so wrapping it directly may lead to getting empty result set in
 * FTL if the object is accessed twice.
 */
public class FetchedResultSet {


    public final ResultSetMetaData metaData;
    public final String[] columnNames;
    public final Map columnIndices;
    public final Object[][] data;


    /**
     * Fetches the specified result set and saves it as an {@link Object[][]}. Also saves its metadata.
     *
     * @param rs the original result set
     * @throws SQLException if a database access error occurs
     */
    public FetchedResultSet(ResultSet rs) throws SQLException {
        metaData = rs.getMetaData();
        int columnCount = metaData.getColumnCount();

        columnNames = new String[columnCount];
        columnIndices = new HashMap(columnNames.length, 1);

        for (int i = 0; i < columnCount; i++) {
            columnNames[i] = metaData.getColumnName(i + 1);
            columnIndices.put(columnNames[i], new Integer(i));
        }

        List rows = new ArrayList(64);

        while (rs.next()) {
            Object[] row = new Object[columnCount];
            for (int i = 0; i < columnCount; i++) {
                Object o = rs.getObject(i + 1);
                if (o instanceof ResultSet) {
                    o = new FetchedResultSet((ResultSet) o);
                }
                row[i] = o;
            }
            rows.add(row);
        }

        data = (Object[][]) rows.toArray(new Object[rows.size()][columnCount]);

        rs.close();
    }


    /**
     * Returns the original {@link ResultSet}'s metadata.
     *
     * @return the metadata
     */
    public ResultSetMetaData getMetaData() {
        return metaData;
    }


}
