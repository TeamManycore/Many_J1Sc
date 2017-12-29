import spinal.sim._
import spinal.core._
import spinal.core.sim._

import java.io._

import jssc._

import java.awt.Graphics
import javax.annotation.Resource
import javax.print.attribute.standard.Destination
import javax.swing.{JFrame, JPanel}

object UARTReceiver {

  // Create an receiver which gets data from the simulation
  def apply(output : SerialPort, uartPin : Bool, baudPeriod : Long) = fork {

    // An UART is high inactive -> wait until simulation starts
    waitUntil(uartPin.toBoolean == true)

    // Simulate the Receiver forever
    while (true) {

      // Look for the rising start bit and wait a half bit time
      waitUntil(uartPin.toBoolean == false)
      sleep(baudPeriod / 2)

      // Check if start bit is still active and wait for first data bit
      sleep(baudPeriod)

      // Hold the received byte
      var buffer = 0

      // Read all 8 data bits
      (0 to 7).suspendable.foreach { bitIdx =>

        // Check the actual data bit
        if (uartPin.toBoolean) {

          // Add a 1 to the received byte
          buffer |= 1 << bitIdx

        }

        // Wait for the next data bit
        sleep(baudPeriod)

      }

      // Write character
      output.writeByte(buffer.toByte)

    }

  }

}

object UARTTransceiver {

  // Create an transceiver which sends data to the simulation
  def apply(input : SerialPort, uartPin : Bool, baudPeriod : Long) = fork {

    // Make the line inactive (high)
    uartPin #= true

    // Simulate the data transmission forever
    while(true) {

      // Check if there is data send by the host
      if(input.getInputBufferBytesCount > 0){

        // get one byte from the host
        val buffer = input.readBytes(1)(0)

        // Create the start bit
        uartPin #= false
        sleep(baudPeriod)

        // Send 8 data bits
        (0 to 7).suspendable.foreach{ bitIdx=>

          // Send bit at position "bitIdx"
          uartPin #= ((buffer >> bitIdx) & 1) != 0
          sleep(baudPeriod)

        }

        // Create stop bit
        uartPin #= true
        sleep(baudPeriod)

      } else {

        // Sleep 10 bit times since no data is available
        sleep(baudPeriod * 10)

      }

    }

  }

}

object J1IcoSim {

  def main(args: Array[String]) : Unit = {

    // Time resolution of the simulation is 1ns
    val simTimeRes = 1e9

    // Number of CPU cycles between some status information
    val simCycles = 10000000l

    // Configuration of CPU-core
    val j1Cfg = J1Config.forth

    // Configuration of the used board
    val boardCfg = CoreConfig.icoBoardSim

    SimConfig.workspacePath("gen/sim")
             .allOptimisation
             //.withWave
             .compile(new J1Ico(j1Cfg, boardCfg)).doSim{dut =>

      // Calculate the number of verilog ticks relative to the given time resolution
      val mainClkPeriod  = (simTimeRes / boardCfg.coreFrequency.getValue.toDouble).toLong
      val uartBaudPeriod = (simTimeRes / boardCfg.uartConfig.baudrate.toDouble).toLong

      // Print some information about the simulation
      println("[J1Sc] Start the simulation of a J1Sc on an IcoBoard")
      println("[J1Sc]  Board frequency is " + boardCfg.coreFrequency.getValue.toDouble + " Hz")
      println("[J1Sc]  UART transmission rate " + boardCfg.uartConfig.baudrate.toLong + " bits/sec")
      println("[J1Sc]  Time resolution is " + 1.0 / simTimeRes + " sec")
      println("[J1Sc]  One clock period in ticks is " + mainClkPeriod + " ticks")
      println("[J1Sc]  Bit time (UART) in ticks is " + uartBaudPeriod + " ticks")

      // Open the (pseudo) serial connection
      val comPort = new SerialPort("/dev/tnt1")
      comPort.openPort()
      comPort.setParams(SerialPort.BAUDRATE_9600,
                        SerialPort.DATABITS_8,
                        SerialPort.STOPBITS_1,
                        SerialPort.PARITY_NONE)

      // Simulate the reset button after some time
      val resetIt = fork {

        // Wait 101 CPU clocks
        sleep(1000000 * mainClkPeriod)

        // Reset the CPU
        //dut.io.reset #= true
        sleep(10 * mainClkPeriod)
        //dut.io.reset #= false
        sleep(10 * mainClkPeriod)

        // Wait some time
        sleep(simCycles)

      }

      // Create the global system - clock
      val genClock = fork {

        // Pretend that the clock is already locked
        dut.io.boardClkLocked #= true

        // Make the reset active
        dut.io.reset #= true

        // Release the reset with clock is low
        dut.io.boardClk #= false
        sleep(mainClkPeriod)
        dut.io.reset #= false
        sleep(mainClkPeriod)

        // Init the cycle counter
        var cycleCounter = 0l

        // Get the actual system time
        var lastTime = System.nanoTime()

        // Simulate forever
        while(true){

          // Simulate a clock signal
          dut.io.boardClk #= false
          sleep(mainClkPeriod / 2)
          dut.io.boardClk #= true
          sleep(mainClkPeriod / 2)

          // Advance the simulated cycles value by one
          cycleCounter += 1

          // Check if we should write some information
          if(cycleCounter == simCycles){

            // Get current system time
            val currentTime = System.nanoTime()

            // Write information about simulation speed
            val deltaTime = (currentTime - lastTime) * 1e-9
            val speedUp   = (simCycles.toDouble /
                             boardCfg.coreFrequency.getValue.toDouble) / deltaTime
            println(f"$simCycles cycles in $deltaTime%4.2f real seconds (Speedup: $speedUp%4.3f)")

            // Store the current system time for the next round and reset the cycle counter
            lastTime = currentTime
            cycleCounter = 0

          }

        }

      }

      // Transmit data from the simulation into the host OS
      UARTReceiver(output = comPort, uartPin = dut.io.tx, baudPeriod = uartBaudPeriod)

      // Receive data from the host OS and send it into the simulation
      UARTTransceiver(input = comPort, uartPin = dut.io.rx, baudPeriod = uartBaudPeriod)

      // Start the simulation
      genClock.join()

      // Close the serial port (never reached)
      assert(comPort.closePort())

    }

  }

}