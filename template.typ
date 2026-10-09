// 英语（一）201 共用模板：封面、页脚、正文与题型布局。
#import "@preview/ezexam:0.3.1" as ezexam
// 2026 考纲的正文、选项中心距约为汉字宽度的 2 倍。
// leading / r-gap 是两行之间的空隙，而不是整个行中心距。
// 书宋 bounds 行盒实测约 0.9em，再留 1.1em 空隙，中心距约 2em。
// 选项区不另加前后留白。
#let exam-line-gap = 1.1em
// 行首含 A./Ⅰ 等西文字形时，bounds 行盒略矮；补 0.1em，
// 保证题干到选项/陈述列表的中心距不短于普通正文行距。
#let choices(..args) = {
  block(above: exam-line-gap + 0.1em, below: 0pt, breakable: true,
    ezexam.choices(r-gap: exam-line-gap, ..args))
}
#let statements(..args) = {
  block(above: exam-line-gap + 0.1em, below: 0pt, breakable: true,
    grid(row-gutter: exam-line-gap, ..args.named(),
      ..args.pos().map(body => block(breakable: false, body))))
}
// 小问使用原生 + 列表；每项整体不跨页，整个列表允许跨页。
#let subquestions(body) = {
  set enum(numbering: "（1）")
  show enum: it => {
    let next-number = if it.start == auto { 1 } else { it.start }
    for item in it.children {
      let explicit = item.fields().at("number", default: none)
      let n = if explicit in (none, auto) { next-number } else { explicit }
      let marker = box(numbering(it.numbering, n))
      block(breakable: false, above: exam-line-gap, below: 0pt,
        inset: (left: 2em))[
        #h(-measure(marker).width - 0.3em)#marker#h(0.3em)#item.body
      ]
      next-number = n + 1
    }
  }
  body
}
#let paper-margin = 17mm
#let exam(
  year: none,
  title: none,
  subject: "计算机学科专业基础",
  code: "408",
  cover: true,
  solutions: false,
  sample: false,
  hide-source-headings: 0,
  wide-labels: false,
  body,
) = {
  let title = if title != none { title } else { str(year) + "年全国硕士研究生招生考试" }
  set document(title: title + " " + subject, date: none)
  set page(width: 176mm, height: 250mm, margin: paper-margin,
    header: none, footer: none)
  set text(font: ("FZShuSong-Z01S"), size: 10.5pt,
    lang: "zh", top-edge: "bounds", bottom-edge: "bounds")
  set par(justify: true, leading: exam-line-gap, spacing: exam-line-gap)
  show math.equation: set text(font: ("New Computer Modern Math", "FZShuSong-Z01S"))
  show math.equation: it => {
    show "e": math.upright
    show "π": math.upright
    it
  }
  show math.equation: it => math.display(it)
  show math.equation.where(block: false): it => h(0.25em, weak: true) + it + h(0.25em, weak: true)
  show math.equation.where(block: true): set block(above: exam-line-gap, below: exam-line-gap)
  set math.cases(gap: 0.65em)
  show math.cases: it => {
    show $&$.body.func(): point => point + h(0.8em)
    it
  }
  set math.mat(align: center, row-gap: 0.65em)
  let numeric-sequence = regex("a^") // 英语正文保留千位分隔符和日期的原有空格。
  show numeric-sequence: it => {
    it.text.split(regex("\\s*[,，]\\s*")).map(text).join(h(0.25em) + [,] + h(0.25em))
  }
  // IPv4（含题目中的 x 通配写法）在每个点后留一个普通空格宽度。
  let ipv4 = regex("[0-9]{1,3}(?:\\.\\s*(?:[0-9]{1,3}|[xX])){3}")
  show ipv4: it => {
    it.text.split(regex("\\.\\s*")).map(text).join([.] + h(0.25em))
  }
  // 代码保留逐字空白，不使用等宽字体、缩小字号或语法高亮。
  // 英文字母、数字与中文使用书宋，其余符号优先使用 MPS。
  set raw(theme: none)
  // raw 默认额外缩到 0.8em，抵消它，字号才真正继承所在正文/表格。
  show raw: set text(font: ("FZShuSong-Z01S"), size: 1em / 0.8)
  show raw: it => {
    // 数字序列的标点规则不改动程序原文。
    show numeric-sequence: it => it
    show regex("[A-Za-z0-9]"): set text(font: "FZShuSong-Z01S")
    it
  }
  // 扫描版的普通单行表格约高 1.8～2 个格内字号；不能沿用正文行距。
  // 行内节点结构已有独立 inset，继续由题内覆盖。
  set table(inset: (x: 0.45em, y: 0.45em))
  set figure(numbering: none, supplement: none)
  // ezexam 的题号使用 question figure 计数，不能一同禁用 numbering。
  show figure.where(kind: "question"): set figure(numbering: "1.")
  set enum(indent: 0.5em, body-indent: 1.8em)

  if cover {
    text(font: "FZHei-B01", size: 12pt)[绝密★启用前]
    v(40pt)
    align(center)[
      #text(size: 13pt)[#title]
      #v(15pt)
      #text(font: "FZHei-B01", size: 20pt)[#subject]
      #if code != none { v(10pt); text(size: 12pt)[（科目代码：#code）] }
      #if sample { v(10pt); text(size: 11pt)[样卷] }
    ]
    v(28pt)
    align(center, text(font: "FZHei-B01", size: 13pt)[考生注意事项])
    v(24pt)
    {
      set enum(numbering: "1.", indent: 0pt, body-indent: 0.55em)
      set par(leading: 1.3em, spacing: 0.9em)
      enum(
        [答题前，考生须在试题册指定位置上填写考生编号和考生姓名；在答题卡指定位置上填写报考单位、考生姓名和考生编号，并涂写考生编号信息点。],
        [选择题的答案必须涂写在答题卡相应题号的选项上，非选择题的答案必须书写在答题卡指定位置的边框区域内。超出答题区域书写的答案无效；在草稿纸、试题册上答题无效。],
        [填（书）写部分必须使用黑色字迹的签字笔书写，字迹工整、笔迹清楚；涂写部分必须使用 2B 铅笔填涂。],
        [考试结束，将答题卡和试题册按规定交回。],
      )
    }
    v(1fr)
    align(center)[（以下信息考生必须认真填写）]
    v(8pt)
    align(center, table(
      columns: (62pt,) + (17pt,) * 15,
      rows: (23pt, 23pt),
      stroke: 0.5pt, inset: 3pt, align: center + horizon,
      [考生编号], ..range(15).map(_ => []),
      [考生姓名], table.cell(colspan: 15)[],
    ))
    v(45pt)
    pagebreak()
    // 阅读版封面后直接进入正文；封面背页补白只由打印版拼版插入。
    counter(page).update(1)
  }

  set page(footer-descent: 17pt,
    footer: align(center, text(font: "FZShuSong-Z01S", size: 9pt)[
      #subject #if solutions [参考答案] else if sample [题型示例] else [试题]　
      第 #context counter(page).display() 页（共 #context counter(page).at(<exam-body-end>).first() 页）
    ]))
  let plain(c) = {
    let f = c.fields()
    if "text" in f { if type(f.text) == str { f.text } else { plain(f.text) } }
    else if "children" in f { f.children.map(plain).join() }
    else if "body" in f { plain(f.body) }
    else { "" }
  }
  // 兼容旧稿的普通文本小问编号，不改变题目内容或原有换行。
  // 处理有分值的综合题，以及没有标注分值的官方题型示例。
  let flatten-sequence(c) = {
    if c.func() == [].func() {
      c.children.map(flatten-sequence).flatten()
    } else { (c,) }
  }
  show math.lr: it => {
    let value = plain(it.body)
    if value.contains(regex("[,，]")) and value.match(regex("^[()\\[\\]{}0-9−+.,，\\s]+$")) != none {
      let compact = flatten-sequence(it.body).map(part => {
        if "text" in part.fields() and part.text in (",", "，") {
          h(0.25em) + math.class("normal", ",") + h(0.25em)
        } else { part }
      }).join()
      // 纯数字序列没有高公式，不需要重新构造伸缩定界符。
      compact
    } else { it }
  }
  let indent-subquestions(description) = {
    if not sample and not plain(description).trim().starts-with(regex("^[（(]\\s*(?:本题\\s*)?[0-9]+\\s*分")) {
      return description
    }
    let parts = flatten-sequence(description)
    let line-start = true
    let split = none
    for (i, part) in parts.enumerate() {
      if part == parbreak() or part.func() == linebreak {
        line-start = true
      } else if part == [ ] {
        continue
      } else {
        if (line-start and part.func() == text and
          part.text.trim().starts-with(regex("^[（(]\\s*1\\s*[）)]"))) {
          split = i
          break
        }
        line-start = false
      }
    }
    if split == none { return description }
    // 小问正文和续行缩进 2em，序号从正文起点向左悬出。
    // 保留原有的段落/强制换行，仅识别行首编号，不触碰代码和表格。
    let items = ()
    let current = ()
    let after-label = false
    line-start = true
    for part in parts.slice(split) {
      if part == parbreak() or part.func() == linebreak {
        current.push(part)
        line-start = true
        after-label = false
      } else if part == [ ] {
        if not after-label { current.push(part) }
      } else {
        if after-label and part.func() == text {
          let value = part.text.trim(at: start)
          if value == "" { continue }
          part = text(value)
        }
        let label = if line-start and part.func() == text {
          part.text.match(regex("^[ \\t]*[（(]\\s*([0-9]+)\\s*[）)][ \\t]*"))
        }
        if label != none {
          // 旧稿转为同一种原生列表；移除小问之间原来的强制换行。
          while current.len() > 0 and current.last() in (parbreak(), linebreak(), [ ]) {
            let _ = current.pop()
          }
          if current.len() > 0 { items.push(current.join()) }
          current = ()
          let rest = part.text.slice(label.end)
          current.push(text(rest))
          after-label = rest == ""
        } else {
          current.push(part)
          after-label = false
        }
        line-start = false
      }
    }
    if current.len() > 0 { items.push(current.join()) }
    parts.slice(0, split).join() + subquestions(enum(..items))
  }
  show heading.where(level: 1): it => context {
    if hide-source-headings == 0 or counter(heading).at(it.location()).first() > hide-source-headings {
      block(above: 1.3em, below: 1.3em, sticky: true,
        text(font: ("Times New Roman", "FZHei-B01"), size: 11pt, weight: "bold", it.body))
    }
  }
  // 不照搬数学模板的全局 show grid：408 的图表和自动选项也使用 grid。
  let question-item(term, description) = {
    set text(font: "FZShuSong-Z01S")
    // 真正缩进整个内容区，而不只是段落；选项、代码和图表随正文悬挂。
    set par(hanging-indent: 0em, first-line-indent: 0em, spacing: exam-line-gap)
    // 分页单位是段落，不是整题；选项 par 和小问的段落也保持完整。
    show par: it => block(breakable: false, above: exam-line-gap, below: 0pt,
      sticky: plain(it.body).trim() == "请回答下列问题。", it)
    if wide-labels {
      [#box(term)#h(0.75em)#indent-subquestions(description)]
    } else {
      block(inset: (left: 2.3em), above: 0pt, below: 0pt, breakable: true)[#h(-1.8em)#box(width: 1.8em, align(left, text(font: "FZHei-B01", term)))#indent-subquestions(description)]
    }
  }
  show terms: it => {
    for item in it.children {
      layout(size => {
        let b = question-item(item.term, item.description)
        block(width: 100%, breakable: true, b)
      })
      parbreak()
    }
  }
  show enum: it => {
    let next-number = if it.start == auto { 1 } else { it.start }
    for item in it.children {
      let explicit = item.fields().at("number", default: none)
      let n = if explicit in (none, auto) { next-number } else { explicit }
      layout(size => {
        let b = question-item(numbering(it.numbering, n), item.body)
        block(width: 100%, breakable: true, b)
      })
      parbreak()
      next-number = n + 1
    }
  }
  show regex("[一二三四五]、[^\\n]*"): t => text(font: "FZHei-B01", t)
  show table: it => {
    // 换行只增加紧凑的一行，不继承正文的 1.3em leading / spacing。
    set par(leading: 0.25em, spacing: 0em, justify: false)
    show par: it => it
    block(breakable: false, it)
  }
  show figure.where(kind: "question"): it => {
    set block(breakable: true)
    layout(size => {
      let b = align(left, it.body)
      block(width: 100%, breakable: true, b)
    })
  }
  body
  // PDF 在正文结束处终止；打印时需要的补白由小册子拼版处理。
  [#metadata(none)<exam-body-end>]
}

#let english-exam(year: 2023, solutions: false, title: none, sample: false, body) = {
  show: exam.with(year: year, subject: "英语（一）", code: "201", solutions: solutions, cover: not solutions, title: title, sample: sample)
  set page(width: 176mm, height: 250mm, margin: 17mm)
  set text(font: ("Times New Roman", "FZShuSong-Z01S"), size: 11pt, lang: "en")
  set par(justify: true, leading: 5pt, spacing: 6pt, first-line-indent: 1em)
  set heading(numbering: none)
  show heading: set text(font: ("Times New Roman", "FZHei-B01"))
  ezexam.mode-state.update(ezexam.HANDOUTS)
  ezexam.answer-state.update(false)
  // 使用 ezexam 自身的题号及 terms 布局，覆盖 408 的中文题目重排。
  show terms: it => context {
    set text(font: ("Times New Roman", "FZShuSong-Z01S"), size: 11pt,
      top-edge: "ascender", bottom-edge: "descender", lang: "en")
    for item in it.children {
      let gap = 0.5em
      let label-width = measure(item.term).width
      block(inset: (left: label-width + gap), above: 0pt, below: 0pt)[
        #set par(first-line-indent: 0pt, hanging-indent: 0pt)
        #h(-label-width - gap)#item.term#h(gap)#item.description
      ]
    }
  }
  show regex("[0-9]+"): set text(font: "Times New Roman")
  show figure.where(kind: "question"): it => align(left, it.body)
  body
}
#let blank(n) = underline(offset: 2pt)[#h(0.5em)#n#h(0.5em)]
#let question(n, stem, ..opts) = {
  ezexam.counter-question.update(n - 1)
  block(breakable: false, above: 14pt, below: 0pt)[
    #set text(font: "Times New Roman", size: 11pt, top-edge: "ascender", bottom-edge: "descender")
    #set par(first-line-indent: 0pt, spacing: 4pt)
    #ezexam.question(label: "1.", line-height: 5pt)[
      #stem
      #ezexam.choices(columns: 1, r-gap: 4pt, spacing: 0.4em, top: 4pt, ..opts.pos())
    ]
  ]
}
#let cloze-options(rows) = {
  set par(first-line-indent: 0pt)
  for (i, row) in rows.enumerate() {
    grid(columns: (18pt, 1fr, 1fr, 1fr, 1fr), column-gutter: 4pt,
      [#(i+1).], ..row.enumerate().map(((j, item)) => [#("ABCD".at(j)). #item]))
    v(4pt)
  }
}
// Part A：纵向单栏，文章与对应题目通过 pagebreak 分页。
#let reading(title, passage, questions, instructions: none) = {
  pagebreak(weak: true)
  if instructions != none {
    [= Section II　Reading Comprehension
    == Part A]
    block(above: 6pt, below: 7pt)[
      #set par(first-line-indent: 0pt)
      *Directions:* #instructions
    ]
  }
  align(center, text(weight: "bold", size: 12pt, title))
  v(6pt)
  passage
  pagebreak()
  questions
  pagebreak(weak: true)
}
#let directions(body) = block(above: 6pt, below: 7pt)[
  #set par(first-line-indent: 0pt)
  *Directions:* #body
]

// Part B 列表：标号独立一列，正文及续行统一缩进，条目间留白。
#let paragraph-item(label, body, gap: 14pt) = block(breakable: false, above: gap, below: gap, inset: (left: 1em))[
  #set text(font: ("Times New Roman", "FZShuSong-Z01S"), size: 11pt, top-edge: "ascender", bottom-edge: "descender")
  #set par(first-line-indent: 0pt, hanging-indent: 0pt, spacing: 6pt)
  #grid(columns: (2.6em, 1fr), column-gutter: 0.4em, align: left + top,
    [#label], body)
]
