const fs = require('fs');

var self = module.exports = {
    readTSV: async (filePath, removeHeader = false, removeColumn1 = false) => {
        let data;
        let headers;
        let rowsData;
        let newRowsData;
        try {
            // Read the CSV file
            data = await fs.promises.readFile(filePath, 'utf8');

            // Split the CSV data into rows
            const rows = data.split('\n');

            // Process each row (assuming the first row contains headers)
            headers = rows[0].split('\t');
            if (removeHeader) {
                rowsData = rows.slice(1).map(row => row.split('\t'));
            } else {
                rowsData = rows.map(row => row.split('\t'));
            }
            if (removeColumn1) {
                newRowsData = rowsData.map(row => row.slice(1).map(cell => cell.trim()));
            } else {
                newRowsData = rowsData.map(row => row.map(cell => cell.trim()));
            }

            // console.log('Headers:', headers);
            // console.log('Data:', newRowsData);
        } catch (err) {
            console.error('Error reading the file:', err);
        }
        return { headers, rowData: newRowsData };
    },


    readCSV: async (filePath, removeHeader = false, removeColumn1 = false) => {
        let data;
        let headers;
        let rowsData;
        let newRowsData;
        try {
            // Read the CSV file
            data = await fs.promises.readFile(filePath, 'utf8');

            // Split the CSV data into rows
            const rows = data.split('\n');

            // Process each row (assuming the first row contains headers)
            headers = rows[0].split(',');
            if (removeHeader) {
                rowsData = rows.slice(1).map(row => row.split(','));
            } else {
                rowsData = rows.map(row => row.split(','));
            }
            if (removeColumn1) {
                newRowsData = rowsData.map(row => row.slice(1).map(cell => cell.trim()));
            } else {
                newRowsData = rowsData.map(row => row.map(cell => cell.trim()));
            }

        } catch (err) {
            console.error('Error reading the file:', err);
        }
        return { headers, rowData: newRowsData };
    }

}