package io.lightfeather.helloworld;

import org.togglz.core.Feature;
import org.togglz.core.annotation.EnabledByDefault;
import org.togglz.core.annotation.Label;
import org.togglz.core.context.FeatureContext;

public enum Features implements Feature {

    @EnabledByDefault
    @Label("Hello World")
    HELLO;

    public boolean isActive() {
        return FeatureContext.getFeatureManager().isActive(this);
    }
}