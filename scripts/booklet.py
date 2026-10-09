"""Impose ISO B5 reading PDFs onto ISO B4 sheets without cropping or scaling."""

from pathlib import Path

from pypdf import PdfReader, PdfWriter, Transformation


MM = 72 / 25.4
PAGE_WIDTH = 176 * MM
PAGE_HEIGHT = 250 * MM
SHEET_WIDTH = 353 * MM
SHEET_HEIGHT = 250 * MM

PRINTING_INSTRUCTIONS = """英语（一）201 小册子打印版

阅读版：ISO B5，试卷和题型示例在封面之后直接进入正文；参考答案无封面。
所有阅读版都没有人工补入的空白页。
文件名以 -print.pdf 结尾的 PDF：已完成小册子拼版，每页是纸张的一面。

打印设置：
  纸张：ISO B4（353 × 250 mm），横向。
  双面：短边翻转；正反面的内容都已保持正向。
  缩放：实际大小 / 100%；每面 1 页。
  不要再启用“小册子”或“每面两页”，避免重复拼版。
  不要跳过空白面，它们属于正确的双面页序。

试卷和题型示例的打印版单独插入封面背页空白和封底空白，
参考答案不插入这两类固定空白。所有打印版均在末尾补齐到 4 页的倍数。
整份文件作为一本小册子：按输出顺序双面打印，叠齐后沿中线对折装订。
字体、图表和原有白边保持不变；ISO B4 比两张 ISO B5 合计宽 1 mm，
两页分别居中放置，不裁边、不缩放，不再添加装订边距。

PDF 中写入了短边翻转和不缩放的打印偏好，但软件/驱动未必采用，
请手动核对设置，并先用一张纸试打，确认纸张尺寸和翻转方向。
打印机不支持 ISO B4 时，应另做目标纸张的拼版，不要假定原字号仍能保留。
"""


def page_order(page_count, *, cover_back_blank=False, back_cover_blank=False):
    """Return zero-based source page pairs, in front/back order for each sheet."""
    if page_count < 1:
        raise ValueError('A booklet requires at least one source page')
    pages = list(range(page_count))
    if cover_back_blank:
        pages.insert(1, None)
    if back_cover_blank:
        pages.append(None)
    pages.extend([None] * (-len(pages) % 4))
    sides = []
    for sheet in range(len(pages) // 4):
        sides.append((pages[-1 - 2 * sheet], pages[2 * sheet]))
        sides.append((pages[2 * sheet + 1], pages[-2 - 2 * sheet]))
    return sides


def build_booklet(source, target, *, cover_back_blank=False, back_cover_blank=False):
    """Preserve PDF page contents at 1:1 size, translating them into two slots."""
    source, target = Path(source), Path(target)
    if source.resolve() == target.resolve():
        raise ValueError('The reading PDF must not be overwritten by its booklet')
    reader = PdfReader(source)
    if reader.is_encrypted:
        raise ValueError('Encrypted PDFs are not supported')
    sides = page_order(len(reader.pages), cover_back_blank=cover_back_blank,
                       back_cover_blank=back_cover_blank)
    for number, page in enumerate(reader.pages, 1):
        if page.rotation or page.user_unit != 1:
            raise ValueError(f'Page {number}: rotated or nonstandard PDF units')
        if (abs(float(page.mediabox.width) - PAGE_WIDTH) > 0.01 or
                abs(float(page.mediabox.height) - PAGE_HEIGHT) > 0.01):
            raise ValueError(f'Page {number}: expected ISO B5 (176 × 250 mm)')
        if any(abs(float(a) - float(b)) > 0.01
               for a, b in zip(page.cropbox, page.mediabox)):
            raise ValueError(f'Page {number}: a cropped reading PDF is not supported')

    writer = PdfWriter()
    for pair in sides:
        sheet = writer.add_blank_page(width=SHEET_WIDTH, height=SHEET_HEIGHT)
        for slot, index in enumerate(pair):
            if index is None:
                continue
            page = reader.pages[index]
            tx = slot * SHEET_WIDTH / 2 + (SHEET_WIDTH / 2 - PAGE_WIDTH) / 2
            tx -= float(page.mediabox.left)
            ty = -float(page.mediabox.bottom)
            sheet.merge_transformed_page(
                page, Transformation().translate(tx=tx, ty=ty), expand=False)
        sheet.compress_content_streams()
    title = reader.metadata.title if reader.metadata else source.stem
    writer.add_metadata({
        '/Title': (title or source.stem) + ' - ISO B4 booklet',
        '/Creator': '408-zhenti vector booklet imposition',
        '/Subject': 'ISO B4 landscape; duplex short edge; actual size 100%; no crop',
    })
    writer.create_viewer_preferences()
    writer.viewer_preferences.duplex = '/DuplexFlipShortEdge'
    writer.viewer_preferences.print_scaling = '/None'
    writer.viewer_preferences.pick_tray_by_pdfsize = True
    writer.write(target)
    return {
        'paper': 'ISO B4',
        'width_mm': 353,
        'height_mm': 250,
        'orientation': 'landscape',
        'duplex': 'short-edge',
        'scale': 1,
        'crop': False,
        'reading_pages': len(reader.pages),
        'cover_back_blank': cover_back_blank,
        'back_cover_blank': back_cover_blank,
        'padding_blank_pages': (len(sides) * 2 - len(reader.pages)
                                - int(cover_back_blank) - int(back_cover_blank)),
        'printed_sides': len(sides),
        'sheets': len(sides) // 2,
        # One-based reading PDF page numbers; null means an inserted blank.
        'page_order': [[None if n is None else n + 1 for n in pair] for pair in sides],
    }
