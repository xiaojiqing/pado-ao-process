import {message, result} from "@permaweb/aoconnect"
import {DATA_PROCESS} from "./constants"
import {getDataProviderWallet, DataProviderWallet, getTag} from "./utils"

export async function testRegistry(dataProviderWallet: DataProviderWallet) {
    let action = "Register"
    let dataTag = Date() 
    let price = JSON.stringify({"price": 1, "symbol": "AOCRED"})
    let data = "data"

    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": dataProviderWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "DataTag", "value": dataTag},
            {"name": "Price", "value": price},
        ],
        "data": data
    });
    
    let Result = await result({
        "process": DATA_PROCESS,
        "message": msgId,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    // console.log(Messages)
    // console.log(Messages[0].Tags)

    return Messages[0].Data
}

async function testGetDataById(dataId: string, dataProviderWallet: DataProviderWallet) {
    let action = "GetDataById"
    
    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": dataProviderWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "DataId", "value": dataId},
        ],
    });

    let Result = await result({
        "process": DATA_PROCESS,
        "message": msgId,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    return Messages[0].Data
}

export async function testAllData(dataProviderWallet: DataProviderWallet) {
    let action = "AllData"

    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": dataProviderWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
        ],
    });

    let Result = await result({
        "process": DATA_PROCESS,
        "message": msgId,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    return Messages[0].Data
}

export async function testDelete(dataId: string, dataProviderWallet: DataProviderWallet) {
    let action = "Delete"

    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": dataProviderWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "DataId", "value": dataId},
        ],
    });

    let Result = await result({
        "process": DATA_PROCESS,
        "message": msgId,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    return Messages[0].Data
}
export async function main() {
	let dataProviderWallet = await getDataProviderWallet();

    let dataId = await testRegistry(dataProviderWallet)
    console.log("dataId: ", dataId)

    let res = await testGetDataById(dataId, dataProviderWallet)
    console.log(`get data by id: ${res}`)

    res = await testAllData(dataProviderWallet)
    console.log(`all data: ${res}`)

    res = await testDelete(dataId, dataProviderWallet)
    console.log(`delete: ${res}`)
}
// main()
