const puppeteer = require("puppeteer");

module.exports = class VideoHelper {
  static async getChannelsFromUrl(url) {
    let browser;
    try {
      browser = await puppeteer.launch({
        headless: true,
        args: ["--no-sandbox", "--disable-setuid-sandbox"],
      });
      const page = await browser.newPage();
      await page.goto(url);
      for (let i = 0; i < 5; i++) {
        await page.evaluate(
          "window.scrollTo(0, document.documentElement.scrollHeight)"
        );
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }

      await page.waitForSelector(
        "ytd-channel-renderer.ytd-item-section-renderer"
      );

      const result = await page.evaluate(function () {
        return Array.from(
          document.querySelectorAll("yt-formatted-string#subscribers")
        ).map((e) => e.textContent);
      });

      return result;
    } catch (err) {
      console.error(err);
      return [];
    } finally {
      if (browser) {
        browser.close();
      }
    }
  }
};
