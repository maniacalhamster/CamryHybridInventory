import puppeteer, { Page } from "puppeteer";
import fs from 'fs';

/**
 * main body of the script I want to run
 * @param {Page} page
 */
async function script(page) {
    const inventory_url = "https://www.toyota.com/search-inventory/model/camryhybrid/?zipcode=91730"
    const graphql_url = "https://api.search-inventory.toyota.com/graphql";
    const distance_sel = 'select[name="distance"]';

    await page.goto(inventory_url);
    await page.waitForSelector(distance_sel);
    page.select(distance_sel, "100").then(() => console.log("set distance"));

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

    fs.writeFile('data.json', JSON.stringify(vehicle_data), (err) => console.log(err))
}

// "main" async function to call. Mainly scaffolding w/ minor configurations
const browser = await puppeteer.launch({headless: false});
async function main() {
    const page = await browser.newPage();
    page.setDefaultTimeout(5000);
    await script(page);
}

// call "main", catching any errors and deferring a final close on browser
main().catch(err => console.log(err)).finally(() => browser?.close())