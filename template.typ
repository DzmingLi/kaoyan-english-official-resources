// 参考 /home/lee/408-zhenti/template.typ 的封面、科目代码与页脚。
#import "template-base.typ": exam
#import "@preview/ezexam:0.3.1" as ezexam
#let english-exam(year: 2023, solutions: false, body) = {
  show: exam.with(year: year, subject: "英语（一）", code: "201", solutions: solutions, cover: not solutions)
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
