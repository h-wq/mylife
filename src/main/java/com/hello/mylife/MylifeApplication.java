package com.hello.mylife;

import com.alibaba.dubbo.spring.boot.annotation.EnableDubboConfiguration;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@EnableDubboConfiguration
public class MylifeApplication {

	public static void main(String[] args) {
		SpringApplication.run(MylifeApplication.class, args);
	}

}
