import {readFileSync} from "node:fs"
import {createDataItemSigner} from "@permaweb/aoconnect"
import Arweave from "arweave"

type WalletKind = "DataProvider" | "ComputationProvider" | "ResultReceiver";
type FilterMessageType = "FilterMessageId" | "FilterMessageTarget"

export interface DataProviderWallet {
    kind: "DataProvider";
    address: string;
    signer: any;
}
export interface ComputationProviderWallet {
    kind: "ComputationProvider";
    address: string;
    signer: any;
}
export interface ResultReceiverWallet {
    kind: "ResultReceiver";
    address: string;
    signer: any;
}

export type Wallet = DataProviderWallet | ComputationProviderWallet | ResultReceiverWallet;

const getArweave = async () => {
    const arweave = Arweave.init({
        "host": "arweave.net",
        "port": 443,
        "protocol": "https",
    });
    return arweave;
}

const getWallet = async (walletFile: string) => {
    const wallet = JSON.parse(
        readFileSync(walletFile).toString()
    );
    return wallet;
}

export const getSigner = async (walletFile: string) => {
    const wallet = await getWallet(walletFile);
    const signer = createDataItemSigner(wallet);
    return signer
}

export const getWalletAddress = async (walletFile: string) => {
    const wallet = await getWallet(walletFile);
    const arweave = await getArweave();
    const address = arweave.wallets.getAddress(wallet);
    return address;
}

export const getFullWallet = async (walletKind: WalletKind, walletFile: string) => {
    let wallet = await getWallet(walletFile)
    let signer = createDataItemSigner(wallet)
    const arweave = await getArweave();
    let address = await arweave.wallets.getAddress(wallet)
    // const kind = walletKind as const

    let fullWallet: Wallet = {kind: walletKind, address: address, signer: signer}
    return fullWallet
}

export const getDataProviderWallet = async () => {
    const dataWallet = await getFullWallet("DataProvider", "data_provider.json") as DataProviderWallet
    return dataWallet
}
export const getComputationProviderWallet = async () => {
    const computeWallet = await getFullWallet("ComputationProvider", "computation_provider.json") as ComputationProviderWallet
    return computeWallet
}
export const getResultReceiverWallet = async () => {
    const resultWallet = await getFullWallet("ResultReceiver", "result_receiver.json") as ResultReceiverWallet
    return resultWallet
}
export const getTag = (Message: any, Tag: string) => {
    const Tags = Message.Tags
    for (let theTag of Tags) {
        if (theTag.name === Tag) {
            return theTag.value
        }
    }
    return null
}
function filterMessageId(msgId: string) {
    return (msg: any) => {
        let mid = getTag(msg, "Message-Id")
        if (mid != null  && mid === msgId) {
            let errorTag = getTag(msg, "Error")
            if (errorTag) {
                throw errorTag
            }
            return true
        }
        return false
    }
}

function filterMessageTarget(target: string) {
    return (msg: any) => {
        return msg.Target === target
    }
}
export async function getMessage(Result: any, msgIdOrTarget: string, filterType: FilterMessageType = "FilterMessageId") {
    let filterFn = filterMessageId(msgIdOrTarget)
    if (filterType == "FilterMessageTarget") {
        filterFn = filterMessageTarget(msgIdOrTarget)
    }
    if (Result.Error) {
        console.log(Result)
        throw Result.Error
    }
    for (let msg of Result.Messages) {
        if (filterFn(msg)) {
            return msg
        }
    }
    for (let msg of Result.Messages) {
        console.log(msg)
    }
    throw msgIdOrTarget + " not found"
}
