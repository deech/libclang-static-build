To build this project:
> mkdir build
> cd build
> "C:\Program Files\CMake\bin\cmake.exe" -G "Visual Studio 16 2019" .. -DCMAKE_INSTALL_PREFIX=..
> "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe" /m -p:Configuration=Release INSTALL.vcxproj

To run:
> cd ..\bin
> clang_visitor.exe
