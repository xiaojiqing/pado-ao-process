import {readFileSync} from "node:fs"
import {createDataItemSigner} from "@permaweb/aoconnect"
import Arweave from "arweave"

type WalletKind = "DataProvider" | "ComputationProvider" | "ResultReceiver";

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
