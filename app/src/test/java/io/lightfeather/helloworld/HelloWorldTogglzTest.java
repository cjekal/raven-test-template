package io.lightfeather.helloworld;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.togglz.core.repository.FeatureState;
import org.togglz.core.repository.StateRepository;
import org.springframework.beans.factory.annotation.Autowired;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;



import static org.hamcrest.Matchers.containsString;


@SpringBootTest
@AutoConfigureMockMvc
public class HelloWorldTogglzTest {


	@Autowired
	private StateRepository state;

    @Autowired
    private MockMvc mockMvc;

	@Test
	public void contextLoads() {
	}

    @Test
    @Disabled
    void testHelloWorldFeatureDisabled() throws Exception {
        state.setFeatureState(new FeatureState(Features.HELLO, false));
        mockMvc.perform(get("/")).andExpect(status().isNotFound());
    }

    @Test
    void testHelloWorldFeatureEnabled() throws Exception {
        mockMvc.perform(get("/")).andExpect(status().isOk())
                .andExpect(content().string(containsString("hello world!")));
    }
}
