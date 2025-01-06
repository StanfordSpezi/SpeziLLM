
import Foundation
import PDFKit


public enum PDFDocumentLoader {
    public static func load(from url: URL) -> [String]? {
        let document = PDFDocument(url: url)
        guard let document else { return nil }
        
        var result: [String] = []
        for pageIndex in 0..<document.pageCount {
            let page = document.page(at: pageIndex)
            if let content = page?.string {
                result.append(content)
            }
        }
        return result
    }
}
