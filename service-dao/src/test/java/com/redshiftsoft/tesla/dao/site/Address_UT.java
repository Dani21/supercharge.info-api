package com.redshiftsoft.tesla.dao.site;

import com.redshiftsoft.tesla.dao.TestAddressCreator;
import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotSame;

public class Address_UT {

    @Test
    public void copyOf() {
        Address address1 = TestAddressCreator.randomAddress();

        Address address2 = Address.copyOf(address1);

        assertNotSame(address1, address2);
        assertEquals(address1, address2);
    }

}
