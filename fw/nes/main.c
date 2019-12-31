#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include "gpio_defs.h"
#include "timer.h"
#include "pano_io.h"
#include "i2c.h"
#include "audio.h"
#include "spiffs.h"
#include "uart_lite.h"
#include "spiffs_drv.h"
#include "Uart.h"

#define DEBUG_LOGGING
#include "log.h"

enum DbgPacketOpCode
{
    DbgPacketOpCodeEcho              = 0x00, // echo packet body back to debugger
    DbgPacketOpCodeCpuMemRd          = 0x01, // read CPU memory
    DbgPacketOpCodeCpuMemWr          = 0x02, // write CPU memory
    DbgPacketOpCodeDbgHlt            = 0x03, // debugger break (stop execution)
    DbgPacketOpCodeDbgRun            = 0x04, // debugger run (resume execution)
    DbgPacketOpCodeCpuRegRd          = 0x05, // read CPU register
    DbgPacketOpCodeCpuRegWr          = 0x06, // read CPU register
    DbgPacketOpCodeQueryHlt          = 0x07, // query if the cpu is currently halted
    DbgPacketOpCodeQueryErrCode      = 0x08, // query NES error code
    DbgPacketOpCodePpuMemRd          = 0x09, // read PPU memory
    DbgPacketOpCodePpuMemWr          = 0x0A, // write PPU memory
    DbgPacketOpCodePpuDisable        = 0x0B, // disable PPU
    DbgPacketOpCodeCartSetCfg        = 0x0C, // set cartridge config from iNES header
};

enum CpuReg
{
    CpuRegPcl = 0x00, // PCL: Program Counter Low
    CpuRegPch = 0x01, // PCH: Program Counter High
    CpuRegAc  = 0x02, // AC:  Accumulator reg
    CpuRegX   = 0x03, // X:   X index reg
    CpuRegY   = 0x04, // Y:   Y index reg
    CpuRegP   = 0x05, // P:   Processor Status reg
    CpuRegS   = 0x06, // S:   Stack Pointer reg
};



#define REG_WR(reg, wr_data)       *((volatile uint32_t *)(reg)) = (wr_data)
#define REG_RD(reg)                *((volatile uint32_t *)(reg))

ContextI2C gI2cCtx = {
   .GpioBase = GPIO_BASE,
   .BitSCL = GPIO_BIT_CODEC_SCL,
   .BitSDA = GPIO_BIT_CODEC_SDA
};

void PlayFiles(spiffs *pFS);
bool ButtonJustPressed(void);
bool NesLoad(char *FileName);
bool SendDbgPacket(char *Buf,int Len,char *RxBuf,int *RxCount);
bool TestNesConnection(void);

spiffs *gSpiffs;

//-----------------------------------------------------------------
// main
//-----------------------------------------------------------------
int main(int argc, char *argv[])
{
   int i;

   LOG("Greatings earthling!\n");

   do {
      Uart_init(NES_UART_BASE);
      if(i2c_init(&gI2cCtx)) {
         ELOG("i2c_init failed\n");
         break;
      }
      LOG("Calling TestNesConnection\n");
      TestNesConnection();
      LOG("Calling audio_init\n");
      audio_init(&gI2cCtx);
      if((gSpiffs = SpiffsMount()) == NULL) {
         ELOG("SpiffsMount failed\n");
         break;
      }
      if(argc > 0) {
         for(i = 0; i < argc; i++) {
            NesLoad(argv[i]);
         }
      }
      else {
         PlayFiles(gSpiffs);
      }
      SpiffsUnmount();
   } while(false);


    for( ; ; );

    return 0;
}

void PlayFiles(spiffs *pFS)
{
    spiffs_DIR dir;
    struct spiffs_dirent ent;
    struct spiffs_dirent *it;
    uint32_t Total = 0;
    char *cp;

    SPIFFS_opendir(pFS,0,&dir);
    for( ; ; ) {
        it = SPIFFS_readdir(&dir, &ent);
        if (!it) {
            break;
        }
        Total += it->size;
        cp = strrchr(it->name,'.');
        if(cp != NULL && strcmp(cp,".nes") == 0) {
           NesLoad(it->name);
           break;
        }
    }
    SPIFFS_closedir(&dir);
    printf("\nTotal %ld\n",Total);
}

bool ButtonJustPressed()
{
   static uint32_t ButtonLast = 3;
   uint32_t Temp;
   int Ret = 0;

   Temp = REG_RD(GPIO_BASE + GPIO_INPUT) & GPIO_BIT_PANO_BUTTON;
   if(ButtonLast != 3 && ButtonLast != Temp) {
      if(Temp == 0) {
         printf("Pano button pressed\n");
         Ret = 1;
      }
   }
   ButtonLast = Temp;

   return Ret;
}

bool NesLoad(char *FileName)
{

   char NesHeader[16];
   spiffs_file fd = SPIFFS_open(gSpiffs,FileName,SPIFFS_O_RDONLY, 0);
   s32_t BytesRead;
   char PrgRomBanks;
   char ChrRomBanks;
   char Mapper;
   #define TRANSFER_LEN    1024
   char Buf[TRANSFER_LEN + 5];
   int PrgRomSize;
   int ChrRomSize;
   unsigned char pclVal;
   unsigned char pchVal;
   int Adr;
   int i;
   bool Error = true;  // Assume the worse

   do {
      if(fd < 0) {
         ELOG("SPIFFS_open(%s) failed\n",FileName);
         break;
      }
      BytesRead = SPIFFS_read(gSpiffs,fd,NesHeader,sizeof(NesHeader));
      if(BytesRead != sizeof(NesHeader)) {
         ELOG("SPIFFS_read failed\n");
         break;
      }

      if(NesHeader[0] != 'N' || NesHeader[1] != 'E' || NesHeader[2] != 'S' ||
         NesHeader[3] != 0x1A)
      {
         ELOG("NES header is invalid\n");
         break;
      }

      PrgRomBanks = NesHeader[4];
      ChrRomBanks = NesHeader[5];

      if(PrgRomBanks > 2) {
         ELOG("Too many program banks: %d, max supported is 2\n",PrgRomBanks);
         break;
      }

      if(ChrRomBanks > 1) {
         ELOG("Too many character rom banks: %d, max supported is 1\n",
              ChrRomBanks);
         break;
      }
         
      if(NesHeader[6] & 0x08) {
         ELOG("Error: Only horizontal and vertical mirroring is supported.\n");
         break;
      }

      Mapper = ((NesHeader[6] & 0xF0) >> 4) | (NesHeader[7] & 0xF0);
      if(Mapper != 0) {
         ELOG("Error: Mapper %d is not supported.\n",Mapper);
         break;
      }
      Error = false;  // Assume the best

      LOG("Loading %s, %d prg banks, %d chr banks, mapper %d\n",FileName,
          PrgRomBanks,ChrRomBanks,Mapper);

      PrgRomSize = PrgRomBanks * 0x4000;
      ChrRomSize = ChrRomBanks * 0x2000;
   // Issue a debug break.
      Buf[0] = DbgPacketOpCodeDbgHlt;
      if(Error = SendDbgPacket(Buf,1,NULL,NULL)) {
         break;
      }

   // Disable the PPU
      Buf[0] = DbgPacketOpCodePpuDisable;
      if(Error = SendDbgPacket(Buf,1,NULL,NULL)) {
         break;
      }

   // Set iNES header info to configure mappers.
      Buf[0] = DbgPacketOpCodeCartSetCfg;
      memcpy(&Buf[1],&NesHeader[4],5);
      if(Error = SendDbgPacket(Buf,6,NULL,NULL)) {
         break;
      }

      Buf[0] = DbgPacketOpCodeCpuMemWr;
      Buf[3] = (char) (TRANSFER_LEN & 0xff);
      Buf[4] = (char) ((TRANSFER_LEN >> 8)& 0xff);

   // Copy PRG ROM data.
      Adr = 0x8000;
      for(i = 0; i < (PrgRomSize / TRANSFER_LEN); i++) {
         Buf[1] = (char) (Adr & 0xff);
         Buf[2] = (char) ((Adr >> 8)& 0xff);

         BytesRead = SPIFFS_read(gSpiffs,fd,&Buf[5],TRANSFER_LEN);
         if(BytesRead < TRANSFER_LEN) {
            ELOG("SPIFFS_read failed (%d)\n",BytesRead);
            Error = true;
            break;
         }
         LOG("Sending adr: 0x%x\n",Adr);
         if(Error = SendDbgPacket(Buf,sizeof(Buf),NULL,NULL)) {
            break;
         }
         Adr += TRANSFER_LEN;
      }
      if(Error) {
         break;
      }

   // Update PC to point at the reset interrupt vector location.
      pclVal = Buf[5 + TRANSFER_LEN - 4];
      pchVal = Buf[5 + TRANSFER_LEN - 3];

   // Copy CHR ROM data.
      Adr = 0;
      Buf[0] = DbgPacketOpCodePpuMemWr;
      for(i = 0; i < (ChrRomSize / TRANSFER_LEN); i++) {
         Buf[1] = (char) (Adr & 0xff);
         Buf[2] = (char) ((Adr >> 8)& 0xff);

         BytesRead = SPIFFS_read(gSpiffs,fd,&Buf[5],TRANSFER_LEN);
         if(BytesRead < TRANSFER_LEN) {
            ELOG("SPIFFS_read failed (%d)\n",BytesRead);
            Error = true;
            break;
         }
         LOG("Sending adr: 0x%x\n",Adr);
         if(Error = SendDbgPacket(Buf,sizeof(Buf),NULL,NULL)) {
            break;
         }
         Adr += TRANSFER_LEN;
      }
      if(Error) {
         break;
      }
      LOG("Loaded Program: %d bytes, character RAM: %d, start address: 0x%02x%02x\n",
          PrgRomSize,ChrRomSize,pchVal,pclVal);

      Buf[0] = DbgPacketOpCodeCpuRegWr;
      Buf[1] = CpuRegPcl;
      Buf[2] = pclVal;
      if(Error = SendDbgPacket(Buf,3,NULL,NULL)) {
         break;
      }

      Buf[0] = DbgPacketOpCodeCpuRegWr;
      Buf[1] = CpuRegPch;
      Buf[2] = pchVal;
      if(Error = SendDbgPacket(Buf,3,NULL,NULL)) {
         break;
      }

      TestNesConnection();

   // Issue a debug run command.
      Buf[0] = DbgPacketOpCodeDbgRun;
      if(Error = SendDbgPacket(Buf,1,NULL,NULL)) {
         break;
      }
   } while(false);

   if(fd >= 0) {
      SPIFFS_close(gSpiffs,fd);
   }

   return Error;
}


bool SendDbgPacket(char *Buf,int Len,char *RxBuf,int *pRxCount)
{
   int i;
   int RxCount = 0;
   int RxLeft = 0;

   if(RxBuf != NULL && pRxCount != NULL) {
      RxLeft = *pRxCount;
   }

   if(Len < 16) {
      LOG("Sending %d bytes:\n",Len);
      LOG_HEX(Buf,Len);
   }
   else {
      LOG("Sending %d bytes\n",Len);
      LOG_HEX(Buf,16);
   }
   for(i = 0; i < Len; i++) {
      if(RxLeft> 0 && Uart_haschar(NES_UART_BASE)) {
         RxLeft--;
         RxBuf[RxCount] = Uart_getchar(NES_UART_BASE);
         LOG_R("Rx: %02x\n",RxBuf[RxCount]);
         RxCount++;
      }
      // LOG_R("Tx: %02x\n",Buf[i]);
      Uart_putc(NES_UART_BASE,Buf[i]);
   }
   if(RxBuf != NULL && pRxCount != NULL) {
      *pRxCount = RxCount;
   }
   return false;
}

bool TestNesConnection(void)
{
   char Buf[] = {DbgPacketOpCodeEcho,4,0,'N','E','S',0};
   char RxBuf[4];
   int RxByte;
   int i;
   int RxCount = sizeof(RxBuf);

// Purge any garbage
   LOG("Purging Rx ...");
   while(Uart_haschar(NES_UART_BASE)) {
      Uart_getchar(NES_UART_BASE);
   }
   LOG_R("\n");
   LOG("Sending echo packet\n");
   SendDbgPacket(Buf,sizeof(Buf),RxBuf,&RxCount);

   // LOG("Received %d bytes while sending\n",RxCount);
   for(i = 0; i < RxCount; i++) {
      if(RxBuf[i] != Buf[i + 3]) {
         ELOG("\nEcho failure, got 0x%02x, expected 0x%02x\n",RxBuf[i],Buf[i+3]);
      }
   }

   // LOG("Waiting for %d more bytes\n",Buf[1] - RxCount);
   for(i = RxCount; i < Buf[1]; i++) {
      while(!Uart_haschar(NES_UART_BASE));
      RxByte = Uart_getchar(NES_UART_BASE);
      LOG("Rx: 0x%02x\n",RxByte);
      if(RxByte != Buf[i + 3]) {
         ELOG("\nEcho failure, got 0x%02x, expected 0x%02x\n",RxByte,Buf[i+3]);
      }
   }
   if(i == Buf[1]) {
      LOG_R("\n");
      LOG("NES communications verified\n");
   }

   return true;
}

