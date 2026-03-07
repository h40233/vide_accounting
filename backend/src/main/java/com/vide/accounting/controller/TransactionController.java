package com.vide.accounting.controller;

import com.vide.accounting.entity.Transaction;
import com.vide.accounting.repository.TransactionRepository;
import com.vide.accounting.dto.TransactionRequest;
import com.vide.accounting.dto.TransactionResponse;
import com.vide.accounting.service.TransactionService;
import com.vide.accounting.util.SecurityUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/transactions")
@Tag(name = "Transactions", description = "Transaction management APIs")
@SecurityRequirement(name = "Bearer Authentication")
public class TransactionController {

    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @GetMapping
    @Operation(summary = "Get all transactions of the user's family")
    public ResponseEntity<List<TransactionResponse>> getTransactions() {
        UUID authUserId = SecurityUtil.getCurrentUserId();
        return ResponseEntity.ok(transactionService.getTransactionsByFamily(authUserId));
    }

    @PostMapping
    @Operation(summary = "Create a new transaction")
    public ResponseEntity<TransactionResponse> createTransaction(@Valid @RequestBody TransactionRequest request) {
        UUID authUserId = SecurityUtil.getCurrentUserId();
        TransactionResponse response = transactionService.createTransaction(authUserId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing transaction")
    public ResponseEntity<TransactionResponse> updateTransaction(
            @PathVariable UUID id,
            @Valid @RequestBody TransactionRequest request) {
        UUID authUserId = SecurityUtil.getCurrentUserId();
        TransactionResponse response = transactionService.updateTransaction(authUserId, id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete an existing transaction")
    public ResponseEntity<Void> deleteTransaction(@PathVariable UUID id) {
        UUID authUserId = SecurityUtil.getCurrentUserId();
        transactionService.deleteTransaction(authUserId, id);
        return ResponseEntity.noContent().build();
    }
}
