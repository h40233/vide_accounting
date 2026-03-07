package com.vide.accounting.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;

public class TransactionRequest {

    @NotNull(message = "金額不能為空")
    @DecimalMin(value = "0.01", message = "金額必須大於 0")
    private BigDecimal amount;

    @NotBlank(message = "分類不能為空")
    private String category;

    @NotBlank(message = "交易類型不能為空 (income/expense/transfer)")
    private String type;

    @NotNull(message = "日期不能為空")
    private LocalDate date;

    private String note;

    public TransactionRequest() {
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public LocalDate getDate() {
        return date;
    }

    public void setDate(LocalDate date) {
        this.date = date;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }
}
