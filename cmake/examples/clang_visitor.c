#include <clang-c/Index.h>
#include <clang-c/CXString.h>
#include <stdio.h>
#include <stdlib.h>

enum CXChildVisitResult visitor(CXCursor cursor, CXCursor parent, CXClientData data) {
    CXSourceLocation location = clang_getCursorLocation( cursor );
    if(!clang_Location_isFromMainFile(location))
        return CXChildVisit_Continue;
    CXString cxspelling = clang_getCursorSpelling(cursor);
    const char* spelling = clang_getCString(cxspelling);
    CXString cxkind = clang_getCursorKindSpelling(clang_getCursorKind(cursor));
    const char* kind = clang_getCString(cxkind);
    printf("Cursor spelling, kind: %s, %s\n", spelling, kind);
    clang_disposeString(cxspelling);
    clang_disposeString(cxkind);
    return CXChildVisit_Recurse;
}

int main(int argc, char** argv) {
    CXIndex idx = clang_createIndex(1,1);
    CXTranslationUnit tu = clang_createTranslationUnitFromSourceFile(idx, "sample.H", 0, 0, 0, 0);
    clang_visitChildren(clang_getTranslationUnitCursor(tu), visitor, 0);
    return 0;
}
