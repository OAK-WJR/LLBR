# LLBR: Language Learner Book Reader

LLBR (Language Learner Book Reader) is an iPhone and iPad app for English learners who read real printed books. Take a photo of a page: LLBR recognizes the text, picks out the words you probably don't know, and shows their meanings in Chinese. In the released app, everything runs on the device.

- App Store: https://apps.apple.com/us/app/llbr/id6479208008 (first released October 23, 2024)
- Support: https://oak-wjr.github.io/LLBR/
- Privacy policy: https://oak-wjr.github.io/LLBR/privacy/

## Which project to open

- `EL-UI/EL-UI.xcodeproj` (scheme EL-UI): the app released on the App Store.
- `LLBR/LLBR.xcodeproj` (scheme EL): the earlier Beta 1.0 version from March 2024.
- `EL-beta/`: development after the App Store release; never released. See [EL-beta/README.md](EL-beta/README.md).

## History

I designed and built LLBR starting in November 2023 and released it on the App Store in October 2024. It began as `EL/`, was renamed `LLBR/` for Beta 1.0 in March 2024, and was replaced in April 2024 by `EL-UI/`, a redesign I had started in January 2024.

When I started in November 2023, a mentor set up a few early files and showed me how to switch between the camera, photo and editing screens; that code is not included in this public copy. The released app's interface (`EL-UI/`) is my own design and code, apart from the adapted code listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

After the release I kept working on the app in `EL-beta/` until November 2025, and during this time I gradually began to use AI coding assistants for parts of the work. That version was never released; [EL-beta/README.md](EL-beta/README.md) describes what it adds.

In 2026 I prepared this public copy with the help of Claude, an AI assistant: we did a privacy and security review and removed personal information, translated code comments, file names and one commit message into English, left out some development files and data not needed here, updated the released app's privacy policy link because the original page is no longer online, matched the version settings to the App Store build, and wrote a short replacement for my mentor's screen-switching file so that the Beta 1.0 project builds. Commit dates and author names are unchanged.

## License

Copyright © 2023–2026 Jiarui Wu.

The code is under the PolyForm Noncommercial License 1.0.0 ([LICENSE](LICENSE)): anyone may use, change and share it for any noncommercial purpose, such as personal study, research, teaching or a hobby project; commercial use is not licensed. Third-party components, and the parts that [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) places under CC BY-SA 4.0 or CC BY 3.0, are licensed as stated there.
