# EL-beta

EL-beta is the version of LLBR that I kept developing after the App Store release, from November 2024 to November 2025. It was never released on the App Store. During this time I gradually began to use AI coding assistants for parts of the work.

## What it adds to the released app

- A new reading view built on PDFKit: each photographed page becomes a PDF page with the unknown words highlighted, and pages are prepared in the background, starting with the one being read.
- Chapters, with a table of contents.
- A first-launch setup: British or American English, a vocabulary level, and an optional short description of your English learning background.
- AI features through the OpenAI API (October 2025): a short Chinese meaning of a word, shown on the word card next to the dictionary meaning, and a filter that stops highlighting words you most likely already know.
- Translation of the whole sentence into Chinese with Google ML Kit (October 2025; switched off again in November 2025).

## Privacy

The released app works entirely on the device; EL-beta does not:

- The AI features send data to OpenAI: each word whose card you open, and the words on each page that you may not know, with your English variety, vocabulary level and learning background. While sentence translation was on, the Chinese translation of the word's sentence was sent too.
- While it was on, sentence translation ran on the device with Google ML Kit, which first downloads its language model from Google.

The released app's privacy policy does not cover these features. EL-beta's consent screen still links to the original policy page, which is no longer online.

## Running it

Run `pod install` in `EL-UI-RP/`, then open `EL-UI-RP/EL-UI.xcworkspace` (scheme EL-UI). The AI features need an OpenAI API key. This development version clears its saved data every time it starts.

## About this copy

In 2026 this copy was cleaned up as described in the [main README](../README.md), and the code comments were translated into English. The changes from October 31 to November 6, 2025, which had never been committed, were added in a 2026 commit. See the main README for the rest of the project and the license.
