// 来源：同一考纲PDF第42—43页；参考答案。通用评分标准见一般评分标准.org。
#import "../../template.typ": *
#show: english-exam.with(year: 2025, title: "2025年全国硕士研究生招生考试", sample: true, solutions: true)
= 参考答案
#let answer-grid(start, answers) = grid(columns: 5, column-gutter: 10pt, row-gutter: 6pt,
  ..answers.enumerate().map(((i, a)) => [#(start + i). #a]))
== I. 英语知识运用（20小题，每题0.5分，共10分）
#answer-grid(1, ("B","C","D","A","D","D","B","A","D","B","C","A","B","C","C","A","C","D","D","B"))

== II. 阅读理解（共60分）
=== A节（20小题，每题2分，共40分）
#answer-grid(21, ("B","D","C","A","C","C","A","D","D","B","C","D","B","A","C","C","D","B","A","B"))

=== B节（5小题，每题2分，共10分）
==== Sample One
#answer-grid(41, ("E","B","G","D","F"))

==== Sample Two
#answer-grid(41, ("B","G","E","D","A"))

==== Sample Three
#answer-grid(41, ("F","C","A","D","G"))

=== C节（5小题，每题2分，共10分）
#paragraph-item("46.", [随着教会的教义和思维模式因文艺复兴而暗淡无光，中世纪和现代两个历史时期之间架起了桥梁，进而通向了崭新和未探索过的知识领域。], gap: 6pt)
#paragraph-item("47.", [在他们的每项发现之前，当时的许多思想家一直沿袭着更加古老的思维模式，其中包括认为地球处于宇宙中心的地心说。], gap: 6pt)
#paragraph-item("48.", [尽管教会屡屡打压这些新一代的逻辑学家和理性主义者，但关于宇宙运行原理的阐释还是不断涌现，其速度让世人再也无法视而不见。], gap: 6pt)
#paragraph-item("49.", [当很多人承担起试图将理性思维和科学思想融入大千世界这一责任时，文艺复兴即告结束，新的时代从此开启。], gap: 6pt)
#paragraph-item("50.", [拉丁语短语“sapere aude”即“敢于求知”准确地概括了这类寻求知识和理解已知信息的行为。], gap: 6pt)

== III. 写作（共30分）
=== A节（1小题，共10分）
51. （略）

=== B节（1小题，共20分）
52. （略）
