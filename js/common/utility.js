// Function to get the second column as a 1D array
const getJthColumnAsArray = (arr, j) => {
    const jColumnArray = [];
    for (let i = 0; i < arr.length; i++) {
        jColumnArray.push(arr[i][j]); // j represents the index of the column
    }
    return jColumnArray;
}

// Doesn't work
const read_account_data = () => {
    let doc;
    try {
        doc = yaml.load(fs.readFileSync('../.aptos/config.yaml', 'utf8'));
    } catch (e) {
        console.log(e);
    }
    return doc;
}

module.exports = { getJthColumnAsArray, read_account_data };