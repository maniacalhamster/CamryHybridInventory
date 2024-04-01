import puppeteer, { Page } from "puppeteer";
import fs from 'fs';
import readline from 'node:readline'

/**
 * main body of the script I want to run
 * @param {Page} page
 */
async function script(page) {
    const inventory_url = `https://www.toyota.com/search-inventory/model/camryhybrid/?zipcode=${zipcode}`
    const graphql_url = "https://api.search-inventory.toyota.com/graphql";
    const distance_sel = 'select[name="distance"]';

    await page.goto(inventory_url);
    await page.waitForSelector(distance_sel);
    page.select(distance_sel, radius).then(() => console.log(`set distance: ${radius}`));

    const vehicle_data = []

    // continue to append data until all graphql queries are completed
    while (true) {
        const resp = await page.waitForResponse(async (response) =>
            response.url() === graphql_url &&
            response.status() === 200 &&
            (await response.json())?.data?.locateVehiclesByZip?.pagination
        );

        const {
            pagination: {
                pageNo: curr_page, 
                totalPages: total_pages,
            },
            vehicleSummary: data_to_append,
        } = (await resp.json()).data.locateVehiclesByZip

        console.log(`Reading response ${curr_page}/${total_pages}: [${data_to_append.length} entries]`);
        vehicle_data.push(...data_to_append)

        if (curr_page && total_pages && curr_page === total_pages) {
            break;
        }
    }

    const _ = fs.writeFile('data.json', JSON.stringify(vehicle_data), (err) => console.log(err))
}

/**
 * "main" async function call 
 * - prompts user for zipcode/radius if not set already
 * - mostly puppeteer scaffolding w/ minor configurations
 * - catches errors
 * - defers a final close on the browser if it still exists
 */
async function main() {
    console.log('Inventory data will be retrieved for dealers within a set radius around a chosen zipcode')
    console.log('Please respond to the following prompts')

    if (!zipcode || !radius) {
        zipcode = await prompt('zipcode: ')
        radius = await prompt('radius: ')
    }

    const browser = await puppeteer.launch({ headless: false });
    const page = await browser.newPage()
    script(page)
      .catch((err) => console.log(err))
      .finally(() => {
        browser?.close()
        rl?.close()
      });
}

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
})
let [zipcode, radius] = [0, 0]

/**
 * util function to transform node:readline question's callbacks into promises
 * @param {string} query 
 * @returns 
 */
const prompt = (query) => new Promise(resolve => rl.question(query, resolve))

main()