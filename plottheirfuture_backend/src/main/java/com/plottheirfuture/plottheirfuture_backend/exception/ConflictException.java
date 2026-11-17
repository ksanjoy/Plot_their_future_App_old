package com.plottheirfuture.plottheirfuture_backend.exception;

import lombok.Getter;

@Getter
public class ConflictException extends RuntimeException {

    private final String registrationStatus;

    public ConflictException(String message) {
        super(message);
        this.registrationStatus = null;
    }

    public ConflictException(String message, String registrationStatus) {
        super(message);
        this.registrationStatus = registrationStatus;
    }
}

