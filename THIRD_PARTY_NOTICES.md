# Third-Party Notices

This file lists the third-party code and data in this repository (see README.md for authorship of everything else). These items remain under their own licenses. The license texts that must accompany them are reproduced at the end of this file.

The app uses Apple's system frameworks (such as SwiftUI, UIKit, Vision, Core Image, NaturalLanguage, AVFoundation, SceneKit, PDFKit and SQLite3) through the iOS SDK. None of their code is included here.

From 2025-10-31 the `EL-beta` project also uses Google ML Kit Translate through CocoaPods (see `EL-beta/EL-UI-RP/Podfile`). None of its code is included here.


---

## 1. WordNet exception lists

**Used for:** looking up the base forms of irregular words (for example *mice -> mouse*, *went -> go*) during lemmatization.

**Files:** `adj.exc`, `adv.exc`, `noun.exc` and `verb.exc` in
`EL-UI/EL-UI/Back-end/ContentProcess/TextFilter/LEWords/` and
`LLBR/LLBR/Back-end/ContentProcess/Picture/TextFilter/LEWords/`. The two folders hold identical copies. The files are in the history from 2024-04-11.

In `EL-beta/EL-UI-RP/EL-UI/Back-end/ContentProcess/TextFilter/`, the same four files are in `LEWords/` from 2024-11-23 and in `LEWords/all/` from 2024-12-26, where `LEWords/easy/` holds identical copies named `*-easy.exc`. `LEWords 2/` (two commits from 2024-12-26) holds `*-easy.exc` lists taken from these files, with some lines added for this project.

**Sources:**

| File | Source | Changes made for LLBR |
|---|---|---|
| `noun.exc` | Princeton WordNet 3.1 | none |
| `adj.exc` | Open English WordNet, 2022 edition | added a second copy of the line `balkier balky` |
| `verb.exc` | Open English WordNet, 2022 edition | added the line `ca can` |
| `adv.exc` | Open English WordNet, 2022 edition (these 7 lines are the same in Princeton WordNet 3.0 and 3.1) | added the line `donot do` |

`other.exc` in the same folders, and `other-easy.exc`, are original to this project and are not taken from WordNet.

**Copyright:**
- WordNet 3.1 Copyright 2011 by Princeton University. All rights reserved.
- Open English Wordnet 2022 Copyright 2022 by the Open English Wordnet team.

**License:**
- Princeton WordNet: the WordNet License (full text in [WordNet License](#wordnet-license) below).
- Open English WordNet: "This resource is derived from Princeton WordNet under the WordNet License and further developed under the Creative Commons Attribution 4.0 International License. You may share and adapt this resource providing attribution is given to both Princeton WordNet and the Open English WordNet team." CC BY 4.0: <https://creativecommons.org/licenses/by/4.0/>. Project page: <https://en-word.net/>.

---

## 2. Lemmatization rules from NLTK

**Used for:** turning inflected words into base forms (for example *boxes -> box*).

**Files:** `Lemmatization.swift` in
`EL-UI/EL-UI/Back-end/ContentProcess/TextFilter/` (from 2024-04-11),
`EL-beta/EL-UI-RP/EL-UI/Back-end/ContentProcess/TextFilter/` (from 2024-11-23),
`LLBR/LLBR/Back-end/ContentProcess/Picture/TextFilter/` (from 2024-03-15) and
`EL/EL/Back-end/ContentProcess/Picture/TextFilter/` (2024-01-06 to 2024-03-09).

**What was adapted:** the suffix substitution table (`morphologicalSubstitutions`) and the exception-file loader (`loadExceptionMap`). They are Swift versions of `MORPHOLOGICAL_SUBSTITUTIONS`, `_FILEMAP` and `_load_exception_map` in NLTK's WordNet corpus reader (`nltk/corpus/reader/wordnet.py`). NLTK's table is based on the morphy rules of Princeton WordNet (see section 1 for the WordNet License).

**Changes made for LLBR:** added the rules `'t -> ""` and `n't -> n` for verbs, `'t -> ""` and `n't -> ""` for adverbs, and `an -> a` for determiners. Words with no part-of-speech tag are tried against every table. Candidate forms are not checked against the WordNet database.

**Copyright:** Copyright (C) 2001-2023 NLTK Project. <https://www.nltk.org/>

**License:** Apache License, Version 2.0 (full text in [Apache License 2.0](#apache-license-20) below).

---

## 3. Apple sample code: "Classifying Images with Vision and Core ML"

This is the 2017 version of the sample, from WWDC 2017. It was also published as "Vision+ML Example".

**Used for:** straightening a photographed page with a perspective correction.

**Files:**
- `EL-UI/EL-UI/Back-end/OriginalProcess/ImageProcessing.swift` (from 2024-04-11)
- `EL-beta/EL-UI-RP/EL-UI/Back-end/OriginalProcess/ImageProcessing.swift` (from 2024-11-23)
- `LLBR/LLBR/Back-end/OriginalProcess/OriginalProcessing.swift` (from 2024-03-15)
- `EL/EL/Back-end/OriginalProcess/OriginalProcessing.swift` (2024-01-06 to 2024-03-09)

**What was adapted:** the perspective-correction steps in `perspectiveCorrectedImage(from:rectangleObservation:)`: the check that the bounding box is valid, the scaling of the four corners, and the `CIPerspectiveCorrection` filter. Also the `CGPoint.scaled(to:)` and `CGRect.scaled(to:)` extensions. These come from the sample's `ViewController.swift` and `Utilities.swift`.

**Changes made for LLBR:** the rectangle comes from `VNDetectDocumentSegmentationRequest` instead of `VNDetectRectanglesRequest`. The function returns the corrected image, without the sample's grayscale and invert filters or its Core ML classification.

**Copyright:** Copyright 2017 Apple Inc.

**License:** BSD 3-Clause (full text in [Apple sample code license](#apple-sample-code-license-bsd-3-clause) below).

---

## 4. Stack Overflow code snippets

User contributions on Stack Overflow are licensed under CC BY-SA 4.0: <https://creativecommons.org/licenses/by-sa/4.0/>. The portions of the files below that were adapted from these answers, including my changes to those portions, are also licensed under CC BY-SA 4.0. The rest of each file is not covered by this license.

| Answer | Author | Used in | What was adapted | Changes made for LLBR |
|---|---|---|---|---|
| [SwiftUI - Custom Camera Implementation Example](https://stackoverflow.com/a/60206177), answer to [SwiftUI Custom Camera View?](https://stackoverflow.com/q/58847638); posted 2020-02-13, edited 2020-08-25 | [ozmpai](https://stackoverflow.com/users/10140530/ozmpai); edit by [Harshil Patel](https://stackoverflow.com/users/14073532) | `EL-UI/EL-UI/ReadingViews/BookContentViews/ResourceEntry/CameraPage.swift` (from 2024-04-11); `EL-beta/EL-UI-RP/EL-UI/Front-end/ReadingViews/BookContentViews/ResourceEntry/CameraPage.swift` (from 2024-11-23) | `CustomCameraRepresentable` with its `Coordinator`, `CustomCameraController`, and the basic structure of `CustomCameraView` | The captured photo is cropped to the screen's aspect ratio and its orientation is fixed. The capture session starts on a background queue. `CustomCameraView` has a new layout, new gestures and new buttons. |
| [How to open the ImagePicker in SwiftUI?](https://stackoverflow.com/a/56516219); posted 2019-06-09, edited 2020-04-08 | [Matteo Pacini](https://stackoverflow.com/users/2890168) | `LLBR/LLBR/Front-end/UIs/CameraView.swift` (from 2024-03-15); `EL/EL/Front-end/UIs/CameraView.swift` (2024-01-17 to 2024-03-09) | the `ImagePicker` struct | none (only whitespace and line breaks differ) |
| [iOS: Image get rotated 90 degree after saved as PNG representation data](https://stackoverflow.com/a/39595508); posted 2016-09-20, edited 2019-09-23 and 2020-01-28 | [Nagendra Rao](https://stackoverflow.com/users/1161412); edit by [Ilesh Panchal](https://stackoverflow.com/users/2910061) | `ImageProcessing.swift` and `OriginalProcessing.swift` (same paths as in section 3; from 2024-01-06) | `UIImage.fixOrientation()` | draws with `UIGraphicsBeginImageContextWithOptions(size, false, scale)` so the image keeps its scale |

---

## 5. English-Chinese dictionary (`Dictionary.db`)

**Used for:** the meanings shown for each word.

**Files:** `Dictionary.db` in `LLBR/LLBR/Back-end/Database/DataFile/` and `EL-UI/EL-UI/Back-end/Database/DataFile/` (earlier in `EL/EL/Back-end/Database/DataFile/`), and in `EL-beta/EL-UI-RP/EL-UI/Back-end/Database/DataFile/` (from 2024-11-23).

**Source:** ECDICT, <https://github.com/skywind3000/ECDICT>.

**Copyright:** Copyright (c) 2017 Linwei

**License:** MIT License (full text in [MIT License](#mit-license) below).

**Changes made for LLBR:** only entries whose headword consists of letters, apostrophes, hyphens or dots and that have a translation were kept, split into one table per initial letter (`A_Words` to `Z_Words`, plus `SPECIAL_Words`) with the columns `word` and `translation`. The translations themselves are unchanged.

---

## 6. Common-word list (`WordFreq` table)

**Used for:** the words a new user is assumed to know already. On first launch
the app copies rows 1 to 3999 of this table into the user's list of learned
words (`LearnedWords.swift`, `populateUserLearned()`).

**File:** the `WordFreq` table in `LearnedWords.db`
(`EL-UI/EL-UI/Back-end/Database/DataFile/`). The other table in the file,
`UserLearned`, is empty and is not covered by this section.

**Source:** Google Books Ngram Viewer dataset, version 3 (20200217), English
1-grams with part-of-speech tags, <https://books.google.com/ngrams>.
Dataset files: <https://storage.googleapis.com/books/ngrams/books/datasetsv3.html>.

**License:** Creative Commons Attribution 3.0 Unported (CC BY 3.0),
<https://creativecommons.org/licenses/by/3.0/>. Google's dataset page states:
"This compilation is licensed under a Creative Commons Attribution 3.0 Unported
License." The table is an adaptation of that dataset and is shared under the
same license. Google does not endorse this project.

**Changes made for LLBR:** only counts from books published 2000 to 2019 were
used. Words were lowercased and inflected forms were combined under one base
form (for example *went*, *goes* and *going* count as *go*); nouns were counted
only where spelled in lowercase, so that names are left out. Google's
part-of-speech tags were mapped to the labels the app uses (noun, verb,
adjective, adverb, pronoun, determiner, other). The words were then ranked by
their combined counts. The table stores only the rank, the label and the word;
it contains no counts.

**Base forms:** irregular forms were mapped with the WordNet exception lists
described in section 1, and base forms were checked against Princeton WordNet
3.0 (see the WordNet License below; WordNet 3.0 Copyright 2006 by Princeton
University. All rights reserved.).

---

## License texts

### WordNet License

Applies to sections 1 and 6, and to the WordNet morphy rules on which section 2 is based.

```text
This software and database is being provided to you, the LICENSEE, by
Princeton University under the following license.  By obtaining, using
and/or copying this software and database, you agree that you have
read, understood, and will comply with these terms and conditions.:

Permission to use, copy, modify and distribute this software and
database and its documentation for any purpose and without fee or
royalty is hereby granted, provided that you agree to comply with
the following copyright notice and statements, including the disclaimer,
and that the same appear on ALL copies of the software, database and
documentation, including modifications that you make for internal
use or for distribution.

WordNet 3.0 Copyright 2006 by Princeton University.  All rights reserved.
WordNet 3.1 Copyright 2011 by Princeton University.  All rights reserved.

THIS SOFTWARE AND DATABASE IS PROVIDED "AS IS" AND PRINCETON
UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, PRINCETON
UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES OF MERCHANT-
ABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE
OF THE LICENSED SOFTWARE, DATABASE OR DOCUMENTATION WILL NOT
INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR
OTHER RIGHTS.

The name of Princeton University or Princeton may not be used in
advertising or publicity pertaining to distribution of the software
and/or database.  Title to copyright in this software, database and
any associated documentation shall at all times remain with
Princeton University and LICENSEE agrees to preserve same.
```

### Apple sample code license (BSD 3-Clause)

Applies to section 3.

```text
Copyright 2017 Apple Inc.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

### Apache License 2.0

Applies to section 2.

```text
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS
```

### MIT License

Applies to section 5.

```text
MIT License

Copyright (c) 2017 Linwei

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Creative Commons Attribution 3.0 Unported

Applies to section 6. Full legal code: <https://creativecommons.org/licenses/by/3.0/legalcode>.
