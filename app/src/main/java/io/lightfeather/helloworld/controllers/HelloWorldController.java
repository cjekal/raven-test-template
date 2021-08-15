package io.lightfeather.helloworld.controllers;

import java.util.concurrent.atomic.AtomicLong;

import io.lightfeather.helloworld.Features;
import io.lightfeather.helloworld.Greeting;
import io.lightfeather.helloworld.services.TestIndexService;
import io.micrometer.core.annotation.Timed;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;

@RestController
@Timed
public class HelloWorldController {

	private final AtomicLong counter = new AtomicLong();

	@Autowired
	TestIndexService testIndexService;

	@GetMapping("/")
	public ResponseEntity<?> index() {
		if (Features.HELLO.isActive()) {
			return ResponseEntity.ok().body(new Greeting(counter.incrementAndGet(), "hello world!"));
		}
		return ResponseEntity.notFound().build();
	}

	@GetMapping("/getid")
	public ResponseEntity<?> esIndexResponse(@RequestBody String id) {
		try {
			String response = testIndexService.get(id);
			return ResponseEntity.ok().body(response);
		} catch (Exception e) {
			System.out.println(e.toString());
		}
		return ResponseEntity.notFound().build();
	}
}
