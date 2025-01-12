#编译qemu工程
SHELL_FOLDER=$(cd "$(dirname "$0")";pwd)
cd qemu-linux
if [ ! -d "$SHELL_FOLDER/output/qemu" ]; then
./configure --prefix=$SHELL_FOLDER/output/qemu  --target-list=riscv64-softmmu --enable-gtk  --enable-virtfs --disable-gio
fi
make -j16
sudo make install

#编译boot启动程序以及测试固件验证串口打印
CROSS_PREFIX=riscv64-linux-gnu

if [ ! -d "SHELL_FOLDER/output/lowlevelboot" ]; then
mkdir $SHELL_FOLDER/output/lowlevelboot
fi
cd  $SHELL_FOLDER/boot
$CROSS_PREFIX-gcc -x assembler-with-cpp -c start.s -o $SHELL_FOLDER/output/lowlevelboot/start.o
$CROSS_PREFIX-gcc -nostartfiles -T./boot.lds -Wl,-Map=$SHELL_FOLDER/output/lowlevelboot/lowlevel_fw.map -Wl,--gc-sections $SHELL_FOLDER/output/lowlevelboot/start.o -o $SHELL_FOLDER/output/lowlevelboot/lowlevel_fw.elf
#使用gnu工具生成原始的程序bin文件
$CROSS_PREFIX-objcopy -O binary -S $SHELL_FOLDER/output/lowlevelboot/lowlevel_fw.elf $SHELL_FOLDER/output/lowlevelboot/lowlevel_fw.bin
# 使用gnu工具生成反汇编文件，方便调试分析（当然我们这个代码太简单，不是很需要）
$CROSS_PREFIX-objdump --source --demangle --disassemble --reloc --wide $SHELL_FOLDER/output/lowlevelboot/lowlevel_fw.elf > $SHELL_FOLDER/output/lowlevelboot.lst

cd  $SHELL_FOLDER/output/lowlevelboot
rm -rf fw.bin
dd of=fw.bin bs=1k count=32k if=/dev/zero
dd of=fw.bin bs=1k conv=notrunc seek=0 if=lowlevel_fw.bin
