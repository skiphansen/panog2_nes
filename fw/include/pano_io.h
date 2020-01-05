#ifndef _PANIO_IO_H_
#define _PANIO_IO_H_

#define GPIO_BASE             0x94000000

#define GPIO_BIT_PANO_BUTTON  0x02
#define GPIO_BIT_RED_LED      0x04
#define GPIO_BIT_GREEN_LED    0x08
#define GPIO_BIT_BLUE_LED     0x10
#define GPIO_BIT_CODEC_SDA    0x20
#define GPIO_BIT_CODEC_SCL    0x40
#define GPIO_BIT_EXPANDER_SDA 0x80
#define GPIO_BIT_EXPANDER_SCL 0x100

#define GPIO_I2C_BITS         (GPIO_BIT_CODEC_SDA | GPIO_BIT_CODEC_SCL  | \
                               GPIO_BIT_EXPANDER_SDA | GPIO_BIT_EXPANDER_SCL)

#define NES_UART_BASE         0x95000000
#endif   // _PANIO_IO_H_

