# Anki PopClip

## Snippet Extension

安装说明：
1. 展开下方的代码块
2. 用鼠标全选代码内容
3. PopClip 会自动识别并提示安装扩展

<details>
<summary>Snippet Code</summary>

```javascript
// #popclip
// name: Anki Q&A
// icon: svg:<svg viewBox="-18 80 80 81"><path d="M35 84c1 1 1 5 2 13 0 11 0 11 3 13 2 1 6 4 10 6s7 4 8 5c3 3 1 5-11 8-12 4-12 4-14 16l-4 13c-2 0-5-4-11-11-3-5-7-8-8-8l-10 0c-18 3-19 1-9-13 3-4 6-8 6-10l-5-11-4-11c0-3 5-3 15 1 5 2 10 3 11 2 1 0 5-3 9-7 8-8 10-9 12-6z" stroke="#00bfff" stroke-width="10" fill="none"/></svg>
// description: Create Anki cards from text with customizable Q/A formats
// options: [
//   {"identifier":"target_deck","label":"Default Deck","type":"string","default value":"Default"},
//   {"identifier":"note_type","label":"Default Note Type","type":"string","default value":"Basic"},
//   {"identifier":"front_field","label":"Front Field","type":"string","default value":"Front"},
//   {"identifier":"back_field","label":"Back Field","type":"string","default value":"Back"},
//   {"identifier":"tag","label":"Tag","type":"string","default value":"PopClip"},
//   {"identifier":"front_regex","label":"Question Pattern","type":"string","default value":"^Q[.:)]"},
//   {"identifier":"back_regex","label":"Answer Pattern","type":"string","default value":"^A[.:)]"}
// ]
// regex: (?s)^.+[\n\s]+.+$
// entitlements: [network]
// language: javascript
const text = popclip.input.text;
const frontRegex = new RegExp(popclip.options.front_regex, "mg");
const backRegex = new RegExp(popclip.options.back_regex, "mg");
const frontMatches = Array.from(text.matchAll(frontRegex));
const backMatches = Array.from(text.matchAll(backRegex));
if (!frontMatches.length || !backMatches.length) {
  popclip.showText("Error: Text must contain both Q and A lines.");
  return;
}
if (frontMatches.length !== backMatches.length) {
  popclip.showText("Error: Number of Q and A don't match.");
  return;
}
const pairs = [];
for (let i = 0; i < frontMatches.length; i++) {
  const frontIndex = frontMatches[i].index;
  const nextFrontIndex = i + 1 < frontMatches.length ? frontMatches[i + 1].index : text.length;
  const backIndex = backMatches[i].index;
  if (backIndex < frontIndex || (i + 1 < frontMatches.length && backIndex > frontMatches[i + 1].index)) continue;
  const front = text.substring(frontIndex, backIndex).replace(frontRegex, "").trim();
  const back = text.substring(backIndex, nextFrontIndex).replace(backRegex, "").trim();
  if (front && back) pairs.push({ front, back });
}
if (!pairs.length) {
  popclip.showText("Error: No valid Q/A found.");
  return;
}
try {
  const axios = require("axios");
  let addedCount = 0;
  for (const pair of pairs) {
    const response = await axios.post("http://localhost:8765", {
      action: "addNote",
      version: 6,
      params: {
        note: {
          deckName: popclip.options.target_deck,
          modelName: popclip.options.note_type,
          fields: {
            [popclip.options.front_field]: pair.front,
            [popclip.options.back_field]: pair.back
          },
          tags: [popclip.options.tag, popclip.context.appName?.replace(/\s+/g, "_") || "PopClip"]
        }
      }
    });
    if (!response.data.error) addedCount++;
  }
  popclip.showText(addedCount > 0 ? `Added ${addedCount} card${addedCount>1?'s':''}` : "Failed to add cards.");
} catch (error) {
  popclip.showText(error.code === "ECONNREFUSED" ? "Failed to connect. Is Anki open?" : `Error: ${error.message}`);
}
```

可以用[下面的文本](https://andymatuschak.org/prompts/)做测试：

```
Q. At what speed should you heat a pot of ingredients for chicken stock?

A. Slowly.

Q. When making chicken stock, when should you lower the heat?

A. After the pot reaches a simmer.

Q. When making chicken stock, what should you do after the pot reaches a simmer?

A. Lower the temperature to a bare simmer.

Q. How long must chicken stock simmer?

A. 90m.
```

</details>

## Legacy PopClip Extension

安装及配置

- 确认已安装 [Anki](https://apps.ankiweb.net/)
- 导入 [Default.apkg](https://github.com/cdpath/anki_tools/releases/download/v0.2.1/Default.apkg)
- 确认已安装 [AnkiConnect](https://ankiweb.net/shared/info/2055492159)
- 在 [Releases](https://github.com/cdpath/anki_tools/releases) 页面下载 anki.popclipextz
- 双击安装，因为没有签名会弹出警告，可忽略
- 初次安装 anki extension 时会提示配置在线字典服务（彩云小译或有道词典），目标牌组（默认 `Default`）和笔记类型（默认 `PopClip`）

翻译服务

- 彩云小译 API 在[这里](https://dashboard.caiyunapp.com/user/sign_in/)申请
- 有道词典解析的网页数据，不需要 API

