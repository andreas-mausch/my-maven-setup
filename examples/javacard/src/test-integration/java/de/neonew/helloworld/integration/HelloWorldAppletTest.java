package de.neonew.helloworld.integration;

import de.neonew.helloworld.HelloWorldApplet;
import static org.assertj.core.api.Assertions.*;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.licel.jcardsim.bouncycastle.util.encoders.Hex;
import com.licel.jcardsim.smartcardio.CardSimulator;
import com.licel.jcardsim.utils.AIDUtil;

import javacard.framework.AID;

public class HelloWorldAppletTest {

    private static final String PACKAGE_AID_HEX = "01020304050607";
    private static CardSimulator simulator;

    @BeforeAll
    static void beforeAll() throws IOException {
        simulator = new CardSimulator();

        // Install applet
        byte[] aid_bytes = Hex.decode(PACKAGE_AID_HEX + "01");

        AID aid = AIDUtil.create(aid_bytes);
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        bos.write(aid_bytes.length);
        bos.write(aid_bytes);

        simulator.installApplet(aid, HelloWorldApplet.class, bos.toByteArray(), (short) 0, (byte) bos.size());
        bos.close();
    }

    @BeforeEach
    void beforeEach() throws IOException {
        simulator.reset();

        byte[] aid_bytes = Hex.decode(PACKAGE_AID_HEX + "01");
        AID aid = AIDUtil.create(aid_bytes);
        simulator.selectApplet(aid);
    }

    @Test
    public void testPing() {
        CommandAPDU apdu = new CommandAPDU(0x80, 0x00, 0, 0);
        ResponseAPDU result = simulator.transmitCommand(apdu);
        assertThat(result.getSW()).isEqualTo(0x9000);
        assertThat(result.getData()).isEqualTo("Hello".getBytes());
    }

    @Test
    public void testUnsupportedCLA() {
        CommandAPDU apdu = new CommandAPDU(0x00, 0x00, 0, 0);
        ResponseAPDU result = simulator.transmitCommand(apdu);
        assertThat(result.getSW()).isEqualTo(0x6E00);
    }

    @Test
    public void testUnsupportedINS() {
        CommandAPDU apdu = new CommandAPDU(0x80, 0xFF, 0, 0);
        ResponseAPDU result = simulator.transmitCommand(apdu);
        assertThat(result.getSW()).isEqualTo(0x6D00);
    }
}
